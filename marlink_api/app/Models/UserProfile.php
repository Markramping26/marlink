<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'avatar_url',
        'bio',
        'battery_pct',
        'sharing_status',
        'sharing_expires_at',
        'show_speed',
        'show_battery',
        'allow_geofence_alerts',
        'last_seen_at',
    ];

    protected function casts(): array
    {
        return [
            'battery_pct' => 'integer',
            'sharing_expires_at' => 'datetime',
            'show_speed' => 'boolean',
            'show_battery' => 'boolean',
            'allow_geofence_alerts' => 'boolean',
            'last_seen_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isSharingActive(): bool
    {
        if ($this->sharing_status !== 'on') {
            return false;
        }

        if ($this->sharing_expires_at !== null && $this->sharing_expires_at->isPast()) {
            return false;
        }

        return true;
    }
}
