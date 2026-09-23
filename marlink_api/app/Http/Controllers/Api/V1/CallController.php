<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\CallSignaled;
use App\Models\Call;
use App\Models\CallParticipant;
use App\Models\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CallController extends ApiBaseController
{
    /**
     * Initiate a real WebRTC voice or video call session.
     */
    public function initiate(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'call_type' => ['required', 'in:voice,video'],
            'participant_ids' => ['required', 'array', 'min:1'],
            'participant_ids.*' => ['integer', 'exists:users,id'],
        ]);

        $call = Call::create([
            'room_id' => $roomId,
            'initiator_id' => $user->id,
            'call_type' => $validated['call_type'],
            'status' => 'calling',
            'started_at' => now(),
        ]);

        // Add initiator
        CallParticipant::create([
            'call_id' => $call->id,
            'user_id' => $user->id,
            'status' => 'joined',
            'joined_at' => now(),
        ]);

        // Add ringing participants and broadcast incoming call signal
        foreach ($validated['participant_ids'] as $participantId) {
            if ($participantId !== $user->id) {
                CallParticipant::create([
                    'call_id' => $call->id,
                    'user_id' => $participantId,
                    'status' => 'ringing',
                ]);

                broadcast(new CallSignaled($participantId, [
                    'type' => 'incoming_call',
                    'call_id' => $call->id,
                    'room_id' => $roomId,
                    'call_type' => $validated['call_type'],
                    'initiator' => [
                        'id' => $user->id,
                        'name' => $user->name,
                        'avatar_url' => $user->profile?->avatar_url,
                    ],
                ]));
            }
        }

        return $this->successResponse([
            'call_id' => $call->id,
            'call_type' => $call->call_type,
            'status' => $call->status,
        ], 'Call initiated.', 201);
    }

    /**
     * Relay WebRTC signaling payloads (SDP offer, SDP answer, ICE candidate).
     */
    public function signal(Request $request, int $callId): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'target_user_id' => ['required', 'integer', 'exists:users,id'],
            'signal_payload' => ['required', 'array'],
        ]);

        $call = Call::findOrFail($callId);

        broadcast(new CallSignaled($validated['target_user_id'], [
            'type' => 'signal_relay',
            'call_id' => $call->id,
            'from_user_id' => $user->id,
            'signal' => $validated['signal_payload'],
        ]));

        return $this->successResponse(null, 'Signal dispatched.');
    }

    /**
     * Terminate or leave a call session.
     */
    public function end(Request $request, int $callId): JsonResponse
    {
        $user = $request->user();
        $call = Call::with('participants')->findOrFail($callId);

        $participant = CallParticipant::where('call_id', $callId)
            ->where('user_id', $user->id)
            ->first();

        if ($participant) {
            $participant->update([
                'status' => 'left',
                'left_at' => now(),
            ]);
        }

        // Notify other participants of hangup
        foreach ($call->participants as $part) {
            if ($part->user_id !== $user->id) {
                broadcast(new CallSignaled($part->user_id, [
                    'type' => 'call_ended',
                    'call_id' => $call->id,
                    'from_user_id' => $user->id,
                ]));
            }
        }

        if ($call->initiator_id === $user->id) {
            $call->update([
                'status' => 'ended',
                'ended_at' => now(),
            ]);
        }

        return $this->successResponse(null, 'Call ended.');
    }
}
