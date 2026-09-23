<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Requests\JoinRoomRequest;
use App\Http\Requests\StoreRoomRequest;
use App\Http\Resources\V1\RoomMemberResource;
use App\Http\Resources\V1\RoomResource;
use App\Models\Room;
use App\Models\RoomMember;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class RoomController extends ApiBaseController
{
    /**
     * List all rooms the authenticated user is a member of.
     */
    public function index(Request $request): JsonResponse
    {
        $rooms = $request->user()->rooms()->with(['members.user.profile', 'members.user.location'])->get();

        return $this->successResponse(RoomResource::collection($rooms), 'Rooms retrieved successfully.');
    }

    /**
     * Create a new room with an auto-generated unique code and assign creator as owner.
     */
    public function store(StoreRoomRequest $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validated();

        $room = DB::transaction(function () use ($user, $validated, $request) {
            $avatarUrl = null;
            if ($request->hasFile('avatar')) {
                $path = $request->file('avatar')->store('room_avatars', 'public');
                $avatarUrl = Storage::disk('public')->url($path);
            }

            $room = Room::create([
                'code' => Room::generateUniqueCode(),
                'name' => $validated['name'],
                'description' => $validated['description'] ?? null,
                'avatar_url' => $avatarUrl,
                'created_by' => $user->id,
                'is_active' => true,
            ]);

            // Assign creator as Room Owner
            RoomMember::create([
                'room_id' => $room->id,
                'user_id' => $user->id,
                'role' => 'owner',
                'is_location_enabled' => true,
                'joined_at' => now(),
            ]);

            return $room;
        });

        $room->load(['members.user.profile', 'members.user.location']);

        return $this->successResponse(new RoomResource($room), 'Room created successfully with code ' . $room->code, 201);
    }

    /**
     * View room details and authorized members.
     */
    public function show(int $roomId): JsonResponse
    {
        $room = Room::with(['members.user.profile', 'members.user.location'])->findOrFail($roomId);

        return $this->successResponse(new RoomResource($room), 'Room details retrieved.');
    }

    /**
     * Join an existing room via room code (e.g. FAM-82K4).
     */
    public function join(JoinRoomRequest $request): JsonResponse
    {
        $user = $request->user();
        $code = strtoupper(trim($request->validated()['code']));

        $room = Room::where('code', $code)->where('is_active', true)->first();

        if (! $room) {
            return $this->errorResponse('Unable to join room. Please check the room code and try again.', [
                'code' => ['Room code not found or inactive.']
            ], 404);
        }

        if ($user->isMemberOfRoom($room->id)) {
            return $this->errorResponse('You are already an active member of this room.', null, 409);
        }

        $membership = RoomMember::create([
            'room_id' => $room->id,
            'user_id' => $user->id,
            'role' => 'member',
            'is_location_enabled' => true,
            'custom_nickname' => $request->validated()['custom_nickname'] ?? null,
            'joined_at' => now(),
        ]);

        $room->load(['members.user.profile', 'members.user.location']);

        return $this->successResponse(new RoomResource($room), "You have joined {$room->name}.", 200);
    }

    /**
     * Leave a room.
     */
    public function leave(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();
        $membership = RoomMember::where('room_id', $roomId)->where('user_id', $user->id)->firstOrFail();

        if ($membership->role === 'owner') {
            // Find next candidate for ownership before leaving
            $nextMember = RoomMember::where('room_id', $roomId)
                ->where('user_id', '!=', $user->id)
                ->orderByRaw("FIELD(role, 'admin', 'member')")
                ->first();

            if ($nextMember) {
                $nextMember->update(['role' => 'owner']);
                Room::where('id', $roomId)->update(['created_by' => $nextMember->user_id]);
            } else {
                // If last person in room leaves, deactivate room
                Room::where('id', $roomId)->update(['is_active' => false]);
            }
        }

        $membership->delete();

        return $this->successResponse(null, 'You have left the room.');
    }

    /**
     * Admin/Owner removes a member from the room.
     */
    public function removeMember(Request $request, int $roomId, int $userId): JsonResponse
    {
        $actorMembership = $request->attributes->get('room_membership');

        if (! $actorMembership || ! $actorMembership->isAdminOrOwner()) {
            return $this->errorResponse('Only room administrators can remove members.', null, 403);
        }

        $targetMembership = RoomMember::where('room_id', $roomId)->where('user_id', $userId)->first();

        if (! $targetMembership) {
            return $this->errorResponse('Member not found in this room.', null, 404);
        }

        if ($targetMembership->role === 'owner') {
            return $this->errorResponse('Room owner cannot be removed.', null, 403);
        }

        $targetMembership->delete();

        return $this->successResponse(null, 'Member has been removed from the room.');
    }

    /**
     * Update room details (name, description, avatar). Admin/Owner only.
     */
    public function update(Request $request, int $roomId): JsonResponse
    {
        $actorMembership = $request->attributes->get('room_membership');

        if (! $actorMembership || ! $actorMembership->isAdminOrOwner()) {
            return $this->errorResponse('Only room administrators can update room details.', null, 403);
        }

        $room = Room::findOrFail($roomId);

        $request->validate([
            'name' => ['sometimes', 'string', 'min:2', 'max:100'],
            'description' => ['nullable', 'string', 'max:500'],
            'avatar' => ['nullable', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
        ]);

        if ($request->has('name')) $room->name = $request->input('name');
        if ($request->has('description')) $room->description = $request->input('description');

        if ($request->hasFile('avatar')) {
            $path = $request->file('avatar')->store('room_avatars', 'public');
            $room->avatar_url = Storage::disk('public')->url($path);
        }

        $room->save();
        $room->load(['members.user.profile', 'members.user.location']);

        return $this->successResponse(new RoomResource($room), 'Room updated successfully.');
    }
}
