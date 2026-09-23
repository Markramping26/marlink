<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Resources\V1\UserResource;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthController extends ApiBaseController
{
    /**
     * Handle user registration.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = DB::transaction(function () use ($validated) {
            $user = User::create([
                'name' => $validated['name'],
                'username' => $validated['username'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'password' => Hash::make($validated['password']),
                'is_active' => true,
            ]);

            // Create default profile with location sharing enabled
            UserProfile::create([
                'user_id' => $user->id,
                'battery_pct' => 100,
                'sharing_status' => 'on',
                'show_speed' => true,
                'show_battery' => true,
                'allow_geofence_alerts' => true,
                'last_seen_at' => now(),
            ]);

            return $user;
        });

        $user->load('profile');
        $token = $user->createToken('marlink-mobile-auth')->plainTextToken;

        return $this->successResponse([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'Registration successful. Welcome to MarLink.', 201);
    }

    /**
     * Handle user login via email or username.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $loginField = filter_var($validated['login'], FILTER_VALIDATE_EMAIL) ? 'email' : 'username';

        $user = User::where($loginField, $validated['login'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return $this->errorResponse('Invalid credentials. Please verify your username/email and password.', [
                'login' => ['These credentials do not match our records.']
            ], 401);
        }

        if (! $user->is_active) {
            return $this->errorResponse('Account is deactivated. Please contact support.', null, 403);
        }

        // Update profile last seen timestamp
        $user->profile()->updateOrCreate(
            ['user_id' => $user->id],
            ['last_seen_at' => now()]
        );

        $deviceName = $validated['device_name'] ?? 'Mobile Client';
        $token = $user->createToken($deviceName)->plainTextToken;

        $user->load('profile');

        return $this->successResponse([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'Login successful.');
    }

    /**
     * Log out current user and revoke token.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->successResponse(null, 'Successfully logged out.');
    }

    /**
     * Fetch authenticated user details.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('profile');

        return $this->successResponse(new UserResource($user), 'User data retrieved.');
    }
}
