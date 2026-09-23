<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = $this->user()->id;

        return [
            'name' => ['sometimes', 'string', 'max:100'],
            'username' => ['sometimes', 'string', 'min:3', 'max:50', 'alpha_dash', Rule::unique('users')->ignore($userId)],
            'phone' => ['nullable', 'string', 'max:30'],
            'bio' => ['nullable', 'string', 'max:255'],
            'avatar' => ['nullable', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'], // max 5MB
            'battery_pct' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'sharing_status' => ['sometimes', Rule::in(['on', 'paused', 'off'])],
            'sharing_duration_minutes' => ['nullable', 'integer', 'min:1'], // e.g. 15, 60, etc.
            'show_speed' => ['sometimes', 'boolean'],
            'show_battery' => ['sometimes', 'boolean'],
            'allow_geofence_alerts' => ['sometimes', 'boolean'],
        ];
    }
}
