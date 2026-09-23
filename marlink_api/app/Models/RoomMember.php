<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RoomMember extends Model
{
    use HasFactory;

    protected $fillable = [
        'room_id',
        'user_id',
        'role',
        'is_location_enabled',
        'custom_nickname',
        'joined_at',
    ];

    protected function casts(): array
    {
        return [
            'is_location_enabled' => 'boolean',
            'joined_at' => 'datetime',
        ];
    }

    public function room(): BelongsTo
    {
        return $this->belongsTo(Room::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isAdminOrOwner(): bool
    {
        return in_array($this->role, ['owner', 'admin'], true);
    }
}
