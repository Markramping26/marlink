<?php

namespace App\Events;

use App\Http\Resources\V1\MessageResource;
use App\Models\Message;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public int $roomId;
    public array $message;

    /**
     * Create a new event instance.
     */
    public function __construct(Message $message)
    {
        $this->roomId = $message->room_id;
        $this->message = (new MessageResource($message->load(['user.profile', 'attachments', 'replyTo'])))->resolve();
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("room.{$this->roomId}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'MessageSent';
    }
}
