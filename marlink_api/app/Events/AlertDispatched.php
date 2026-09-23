<?php

namespace App\Events;

use App\Http\Resources\V1\AlertResource;
use App\Models\Alert;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class AlertDispatched implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public int $roomId;
    public array $alert;

    /**
     * Create a new event instance.
     */
    public function __construct(Alert $alert)
    {
        $this->roomId = $alert->room_id;
        $this->alert = (new AlertResource($alert->load(['sender.profile', 'targetUser.profile'])))->resolve();
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
        return 'AlertDispatched';
    }
}
