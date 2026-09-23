<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CallSignaled implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public int $targetUserId;
    public array $signalData;

    /**
     * Create a new event instance.
     */
    public function __construct(int $targetUserId, array $signalData)
    {
        $this->targetUserId = $targetUserId;
        $this->signalData = $signalData;
    }

    /**
     * WebRTC signaling is routed strictly to the specific user's private channel.
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("user.{$this->targetUserId}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'CallSignaled';
    }
}
