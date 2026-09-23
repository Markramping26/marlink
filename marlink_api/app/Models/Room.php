<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Room extends Model
{
    use HasFactory;

    protected $fillable = [
        'code',
        'name',
        'description',
        'avatar_url',
        'created_by',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public static function generateUniqueCode(): string
    {
        do {
            // Generates formatted code: e.g. FAM-82K4 or MLK-9X72
            $prefix = strtoupper(Str::random(3));
            $suffix = strtoupper(Str::random(4));
            $code = "{$prefix}-{$suffix}";
        } while (self::where('code', $code)->exists());

        return $code;
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function members(): HasMany
    {
        return $this->hasMany(RoomMember::class);
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'room_members')
            ->withPivot(['role', 'is_location_enabled', 'custom_nickname', 'joined_at'])
            ->withTimestamps();
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function alerts(): HasMany
    {
        return $this->hasMany(Alert::class);
    }

    public function places(): HasMany
    {
        return $this->hasMany(Place::class);
    }

    public function calls(): HasMany
    {
        return $this->hasMany(Call::class);
    }
}
