<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'username',
        'email',
        'phone',
        'password',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    public function profile(): HasOne
    {
        return $this->hasOne(UserProfile::class);
    }

    public function roomMemberships(): HasMany
    {
        return $this->hasMany(RoomMember::class);
    }

    public function rooms()
    {
        return $this->belongsToMany(Room::class, 'room_members')
            ->withPivot(['role', 'is_location_enabled', 'custom_nickname', 'joined_at'])
            ->withTimestamps();
    }

    public function location(): HasOne
    {
        return $this->hasOne(Location::class);
    }

    public function locationHistories(): HasMany
    {
        return $this->hasMany(LocationHistory::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function sentAlerts(): HasMany
    {
        return $this->hasMany(Alert::class, 'sender_id');
    }

    public function receivedAlerts(): HasMany
    {
        return $this->hasMany(Alert::class, 'target_user_id');
    }

    public function deviceTokens(): HasMany
    {
        return $this->hasMany(DeviceToken::class);
    }

    public function isMemberOfRoom(int $roomId): bool
    {
        return $this->roomMemberships()->where('room_id', $roomId)->exists();
    }
}
