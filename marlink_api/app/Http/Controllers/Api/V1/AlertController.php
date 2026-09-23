<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\AlertDispatched;
use App\Http\Resources\V1\AlertResource;
use App\Models\Alert;
use App\Models\RoomMember;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AlertController extends ApiBaseController
{
    /**
     * Dispatch an Attention Alert to a member or entire room.
     * Rate-limited to prevent notification spam.
     */
    public function dispatchAttention(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'target_user_id' => ['nullable', 'exists:users,id'],
            'alert_type' => ['required', 'in:attention,meet_here,leaving,arrived,check_on_me'],
            'message' => ['nullable', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
        ]);

        // Anti-spam cooldown check: max 1 alert per 30 seconds from same sender to same target
        $recentAlert = Alert::where('room_id', $roomId)
            ->where('sender_id', $user->id)
            ->where('target_user_id', $validated['target_user_id'] ?? null)
            ->where('created_at', '>=', now()->subSeconds(30))
            ->exists();

        if ($recentAlert) {
            return $this->errorResponse('Please wait 30 seconds before sending another attention alert to this member.', null, 429);
        }

        $alert = Alert::create([
            'room_id' => $roomId,
            'sender_id' => $user->id,
            'target_user_id' => $validated['target_user_id'] ?? null,
            'alert_type' => $validated['alert_type'],
            'status' => 'active',
            'latitude' => $validated['latitude'] ?? null,
            'longitude' => $validated['longitude'] ?? null,
            'metadata' => [
                'note' => $validated['message'] ?? null,
            ],
        ]);

        $alert->load(['sender.profile', 'targetUser.profile']);

        broadcast(new AlertDispatched($alert))->toOthers();

        return $this->successResponse(new AlertResource($alert), 'Attention alert sent.', 201);
    }

    /**
     * Trigger an SOS Emergency Alert with current telemetry.
     */
    public function triggerSos(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'speed' => ['nullable', 'numeric'],
            'battery_pct' => ['nullable', 'integer', 'between:0,100'],
            'emergency_note' => ['nullable', 'string', 'max:500'],
        ]);

        $alert = Alert::create([
            'room_id' => $roomId,
            'sender_id' => $user->id,
            'target_user_id' => null, // Room-wide emergency broadcast
            'alert_type' => 'sos',
            'status' => 'active',
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'metadata' => [
                'speed' => $validated['speed'] ?? null,
                'battery_pct' => $validated['battery_pct'] ?? null,
                'note' => $validated['emergency_note'] ?? 'Emergency SOS triggered',
                'timestamp' => now()->toIso8601String(),
            ],
        ]);

        $alert->load(['sender.profile']);

        // High priority broadcast
        broadcast(new AlertDispatched($alert))->toOthers();

        return $this->successResponse(new AlertResource($alert), 'Emergency SOS alert activated.', 201);
    }

    /**
     * Acknowledge an active alert.
     */
    public function acknowledge(Request $request, int $roomId, int $alertId): JsonResponse
    {
        $alert = Alert::where('room_id', $roomId)->where('id', $alertId)->firstOrFail();

        $alert->update([
            'status' => 'acknowledged',
            'acknowledged_at' => now(),
            'acknowledged_by' => $request->user()->id,
        ]);

        $alert->load(['sender.profile', 'targetUser.profile']);
        broadcast(new AlertDispatched($alert))->toOthers();

        return $this->successResponse(new AlertResource($alert), 'Alert acknowledged.');
    }

    /**
     * Cancel an active SOS alert (Initiator only).
     */
    public function cancelSos(Request $request, int $roomId, int $alertId): JsonResponse
    {
        $alert = Alert::where('room_id', $roomId)->where('id', $alertId)->firstOrFail();

        if ($alert->sender_id !== $request->user()->id) {
            return $this->errorResponse('Only the initiator can cancel this emergency alert.', null, 403);
        }

        $alert->update([
            'status' => 'cancelled',
        ]);

        $alert->load(['sender.profile']);
        broadcast(new AlertDispatched($alert))->toOthers();

        return $this->successResponse(new AlertResource($alert), 'SOS emergency cancelled.');
    }
}
