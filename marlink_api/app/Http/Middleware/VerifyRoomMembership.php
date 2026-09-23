<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class VerifyRoomMembership
{
    /**
     * Handle an incoming request and ensure authenticated user is an authorized member of the room.
     */
    public function handle(Request $request, Closure $next, ?string $requiredRole = null): Response
    {
        $user = $request->user();
        $roomId = $request->route('room') ?? $request->route('roomId') ?? $request->input('room_id');

        if (!$roomId) {
            return response()->json([
                'success' => false,
                'message' => 'Room identifier missing from request.',
                'errors' => (object)[],
            ], 400);
        }

        // Handle numeric ID or Route-model binding
        if (is_object($roomId)) {
            $roomId = $roomId->id;
        }

        $membership = $user->roomMemberships()->where('room_id', $roomId)->first();

        if (!$membership) {
            return response()->json([
                'success' => false,
                'message' => 'Access denied. You are not a member of this room.',
                'errors' => (object)[],
            ], 403);
        }

        if ($requiredRole === 'admin' && !$membership->isAdminOrOwner()) {
            return response()->json([
                'success' => false,
                'message' => 'Administrative privileges required for this action.',
                'errors' => (object)[],
            ], 403);
        }

        // Attach membership to request for controller convenience
        $request->attributes->set('room_membership', $membership);

        return $next($request);
    }
}
