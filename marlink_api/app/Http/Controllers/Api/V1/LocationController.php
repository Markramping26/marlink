<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\LocationUpdated;
use App\Models\Location;
use App\Models\LocationHistory;
use App\Models\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LocationController extends ApiBaseController
{
    /**
     * Ingest an updated GPS location fix from mobile client.
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $profile = $user->profile;

        $validated = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'accuracy' => ['nullable', 'numeric', 'min:0'],
            'altitude' => ['nullable', 'numeric'],
            'speed' => ['nullable', 'numeric', 'min:0'],
            'heading' => ['nullable', 'numeric', 'between:0,360'],
            'battery_pct' => ['nullable', 'integer', 'between:0,100'],
            'is_moving' => ['nullable', 'boolean'],
            'save_history' => ['nullable', 'boolean'],
        ]);

        // If location sharing is OFF or PAUSED, we do NOT broadcast to rooms
        $isSharing = $profile ? $profile->isSharingActive() : false;

        $now = now();

        // Update or create current location record
        $location = Location::updateOrCreate(
            ['user_id' => $user->id],
            [
                'latitude' => $validated['latitude'],
                'longitude' => $validated['longitude'],
                'accuracy' => $validated['accuracy'] ?? null,
                'altitude' => $validated['altitude'] ?? null,
                'speed' => $validated['speed'] ?? null,
                'heading' => $validated['heading'] ?? null,
                'battery_pct' => $validated['battery_pct'] ?? $profile?->battery_pct,
                'is_moving' => $validated['is_moving'] ?? false,
                'recorded_at' => $now,
            ]
        );

        // Update profile battery and last seen
        if ($profile) {
            if (isset($validated['battery_pct'])) {
                $profile->battery_pct = $validated['battery_pct'];
            }
            $profile->last_seen_at = $now;
            $profile->save();
        }

        // Optional location history trail (strictly opt-in)
        if (!empty($validated['save_history'])) {
            LocationHistory::create([
                'user_id' => $user->id,
                'latitude' => $validated['latitude'],
                'longitude' => $validated['longitude'],
                'speed' => $validated['speed'] ?? null,
                'heading' => $validated['heading'] ?? null,
                'recorded_at' => $now,
            ]);
        }

        // If sharing is active, broadcast to all rooms where the user is an active member
        if ($isSharing) {
            $userRooms = $user->roomMemberships()->where('is_location_enabled', true)->pluck('room_id');
            foreach ($userRooms as $roomId) {
                broadcast(new LocationUpdated($roomId, $user, $location))->toOthers();
            }
        }

        return $this->successResponse([
            'is_sharing_active' => $isSharing,
            'recorded_at' => $now->toIso8601String(),
        ], 'Location updated successfully.');
    }

    /**
     * Get live locations of all sharing members in a room.
     */
    public function roomLocations(Request $request, int $roomId): JsonResponse
    {
        $room = Room::findOrFail($roomId);

        // Query members who have location sharing enabled and profile sharing active
        $members = $room->members()
            ->with(['user.profile', 'user.location'])
            ->get();

        $activeLocations = [];

        foreach ($members as $member) {
            $user = $member->user;
            $profile = $user?->profile;
            $location = $user?->location;

            if ($profile && $profile->isSharingActive() && $member->is_location_enabled && $location) {
                $activeLocations[] = [
                    'user_id' => $user->id,
                    'name' => $user->name,
                    'username' => $user->username,
                    'custom_nickname' => $member->custom_nickname,
                    'avatar_url' => $profile->avatar_url,
                    'latitude' => $location->latitude,
                    'longitude' => $location->longitude,
                    'accuracy' => $location->accuracy,
                    'speed' => $profile->show_speed ? $location->speed : null,
                    'heading' => $location->heading,
                    'battery_pct' => $profile->show_battery ? $location->battery_pct : null,
                    'is_moving' => $location->is_moving,
                    'recorded_at' => $location->recorded_at->toIso8601String(),
                ];
            }
        }

        return $this->successResponse($activeLocations, 'Active room locations retrieved.');
    }

    /**
     * Fetch user's own location history trail.
     */
    public function history(Request $request): JsonResponse
    {
        $history = LocationHistory::where('user_id', $request->user()->id)
            ->orderBy('recorded_at', 'desc')
            ->limit(500)
            ->get(['latitude', 'longitude', 'speed', 'heading', 'recorded_at']);

        return $this->successResponse($history, 'Location history retrieved.');
    }

    /**
     * Clear all user's historical location data.
     */
    public function clearHistory(Request $request): JsonResponse
    {
        LocationHistory::where('user_id', $request->user()->id)->delete();

        return $this->successResponse(null, 'Location history cleared.');
    }
}
