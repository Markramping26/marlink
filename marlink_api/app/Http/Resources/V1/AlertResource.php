<?php

namespace App\Http\Resources\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AlertResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $sender = $this->sender;
        $target = $this->targetUser;

        return [
            'id' => $this->id,
            'room_id' => $this->room_id,
            'alert_type' => $this->alert_type,
            'status' => $this->status,
            'is_sos' => $this->isSos(),
            'sender' => [
                'id' => $sender?->id,
                'name' => $sender?->name,
                'username' => $sender?->username,
                'avatar_url' => $sender?->profile?->avatar_url,
            ],
            'target_user' => $target ? [
                'id' => $target->id,
                'name' => $target->name,
                'username' => $target->username,
            ] : null,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'metadata' => $this->metadata,
            'acknowledged_at' => $this->acknowledged_at?->toIso8601String(),
            'acknowledged_by' => $this->acknowledged_by,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
