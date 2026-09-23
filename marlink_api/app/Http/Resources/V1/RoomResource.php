<?php

namespace App\Http\Resources\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RoomResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,
            'description' => $this->description,
            'avatar_url' => $this->avatar_url,
            'created_by' => $this->created_by,
            'is_active' => (bool) $this->is_active,
            'members_count' => $this->members()->count(),
            'members' => RoomMemberResource::collection($this->whenLoaded('members')),
            'current_user_role' => $this->whenPivotLoaded('room_members', function () {
                return $this->pivot->role;
            }),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
