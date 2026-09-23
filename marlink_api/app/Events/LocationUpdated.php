<?php

namespace App\Events;

use App\Models\Location;
use App\Models\User;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class LocationUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public int $roomId;
    public int $userId;
    public array $telemetry;

    /**
     * Create a new event instance.
     */
    public function __construct(int $roomId, User $user, Location $location)
    {
        $this->roomId = $roomId;
        $this->userId = $user->id;

        $profile = $user->profile;

        $this->telemetry = [
            'user_id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'avatar_url' => $profile?->avatar_url,
            'latitude' => $location->latitude,
            'longitude' => $location->longitude,
            'accuracy' => $location->accuracy,
            'speed' => ($profile?->show_speed) ? $location->speed : null,
            'heading' => $location->heading,
            'battery_pct' => ($profile?->show_battery) ? $location->battery_pct : null,
            'is_moving' => $location->is_moving,
            'recorded_at' => $location->recorded_at->toIso8601String(),
        ];
    }

    /**
     * Broadcast on private room channel. Only authorized room members can listen.
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("room.{$this->roomId}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'LocationUpdated';
    }
}
