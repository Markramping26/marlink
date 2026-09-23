<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
*/

// Private Room Channel (Location, Chat, Alerts, SOS)
Broadcast::channel('room.{roomId}', function (User $user, int $roomId) {
    return $user->isMemberOfRoom($roomId);
});

// Presence Room Channel (Online/Offline Member Status)
Broadcast::channel('presence-room.{roomId}', function (User $user, int $roomId) {
    if ($user->isMemberOfRoom($roomId)) {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'avatar_url' => $user->profile?->avatar_url,
            'sharing_status' => $user->profile?->sharing_status ?? 'off',
        ];
    }

    return false;
});

// Private User Channel (Direct notifications, WebRTC incoming calls)
Broadcast::channel('user.{userId}', function (User $user, int $userId) {
    return (int) $user->id === (int) $userId;
});
