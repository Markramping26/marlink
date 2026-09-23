<?php

namespace App\Http\Resources\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'avatar_url' => $this->avatar_url,
            'bio' => $this->bio,
            'battery_pct' => $this->battery_pct,
            'sharing_status' => $this->sharing_status,
            'is_sharing_active' => $this->isSharingActive(),
            'sharing_expires_at' => $this->sharing_expires_at?->toIso8601String(),
            'show_speed' => $this->show_speed,
            'show_battery' => $this->show_battery,
            'allow_geofence_alerts' => $this->allow_geofence_alerts,
            'last_seen_at' => $this->last_seen_at?->toIso8601String(),
        ];
    }
}
