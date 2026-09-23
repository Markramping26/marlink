<?php

namespace App\Http\Resources\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user = $this->user;
        $profile = $user?->profile;

        return [
            'id' => $this->id,
            'room_id' => $this->room_id,
            'user_id' => $this->user_id,
            'sender' => [
                'id' => $user?->id,
                'name' => $user?->name,
                'username' => $user?->username,
                'avatar_url' => $profile?->avatar_url,
            ],
            'reply_to' => $this->replyTo ? [
                'id' => $this->replyTo->id,
                'content' => $this->replyTo->content,
                'sender_name' => $this->replyTo->user?->name,
            ] : null,
            'message_type' => $this->message_type,
            'content' => $this->is_deleted ? 'This message was deleted' : $this->content,
            'location' => ($this->message_type === 'location' && !$this->is_deleted) ? [
                'latitude' => $this->latitude,
                'longitude' => $this->longitude,
                'label' => $this->location_label,
            ] : null,
            'attachments' => $this->is_deleted ? [] : $this->attachments->map(function ($att) {
                return [
                    'id' => $att->id,
                    'file_url' => $att->file_url,
                    'file_name' => $att->file_name,
                    'file_size' => $att->file_size,
                    'mime_type' => $att->mime_type,
                ];
            }),
            'is_deleted' => (bool) $this->is_deleted,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
