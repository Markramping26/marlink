<?php

namespace App\Http\Resources\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RoomMemberResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user = $this->user;
        $profile = $user?->profile;
        $location = $user?->location;

        $isSharing = $profile ? $profile->isSharingActive() : false;

        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'name' => $user?->name,
            'username' => $user?->username,
            'custom_nickname' => $this->custom_nickname,
            'display_name' => $this->custom_nickname ?: $user?->name,
            'avatar_url' => $profile?->avatar_url,
            'role' => $this->role,
            'is_location_enabled' => (bool) $this->is_location_enabled,
            'sharing_status' => $profile?->sharing_status ?? 'off',
            'is_sharing_active' => $isSharing,
            'battery_pct' => ($profile?->show_battery && $profile?->battery_pct !== null) ? $profile->battery_pct : null,
            'last_seen_at' => $profile?->last_seen_at?->toIso8601String(),
            'joined_at' => $this->joined_at?->toIso8601String(),
            // Location telemetry (only exposed if sharing is active and permitted)
            'location' => $isSharing && $location ? [
                'latitude' => $location->latitude,
                'longitude' => $location->longitude,
                'accuracy' => $location->accuracy,
                'speed' => $profile?->show_speed ? $location->speed : null,
                'heading' => $location->heading,
                'is_moving' => $location->is_moving,
                'battery_pct' => $profile?->show_battery ? $location->battery_pct : null,
                'recorded_at' => $location->recorded_at?->toIso8601String(),
            ] : null,
        ];
    }
}
