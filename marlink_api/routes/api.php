<?php

use App\Http\Controllers\Api\V1\AlertController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CallController;
use App\Http\Controllers\Api\V1\ChatController;
use App\Http\Controllers\Api\V1\LocationController;
use App\Http\Controllers\Api\V1\PlaceController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\RoomController;
use App\Http\Middleware\VerifyRoomMembership;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| MarLink API Routes - Version 1
|--------------------------------------------------------------------------
| All routes are prefixed with /api/v1
*/

Route::prefix('v1')->group(function () {

    // --- 1. Public Authentication Routes ---
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login', [AuthController::class, 'login']);
    });

    // --- 2. Authenticated Endpoints ---
    Route::middleware('auth:sanctum')->group(function () {

        // Session & Profile
        Route::prefix('auth')->group(function () {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('me', [AuthController::class, 'me']);
        });

        Route::put('user/profile', [ProfileController::class, 'update']);

        // User Location Updates & Personal History
        Route::prefix('locations')->group(function () {
            Route::post('update', [LocationController::class, 'update']);
            Route::get('history', [LocationController::class, 'history']);
            Route::delete('history', [LocationController::class, 'clearHistory']);
        });

        // Room Discovery & Joining
        Route::prefix('rooms')->group(function () {
            Route::get('/', [RoomController::class, 'index']);
            Route::post('/', [RoomController::class, 'store']);
            Route::post('join', [RoomController::class, 'join']);

            // --- Protected Room-Specific Routes (Strict Membership Authorization) ---
            Route::middleware(VerifyRoomMembership::class)->prefix('{roomId}')->group(function () {
                // Room Details & Member Management
                Route::get('/', [RoomController::class, 'show']);
                Route::put('/', [RoomController::class, 'update']);
                Route::post('leave', [RoomController::class, 'leave']);
                Route::delete('members/{userId}', [RoomController::class, 'removeMember']);

                // Live Member Locations
                Route::get('locations', [LocationController::class, 'roomLocations']);

                // Messaging & Media
                Route::prefix('messages')->group(function () {
                    Route::get('/', [ChatController::class, 'index']);
                    Route::post('/', [ChatController::class, 'store']);
                    Route::post('media', [ChatController::class, 'uploadMedia']);
                    Route::delete('{messageId}', [ChatController::class, 'destroy']);
                });

                // Attention Alerts & SOS
                Route::prefix('alerts')->group(function () {
                    Route::post('/', [AlertController::class, 'dispatchAttention']);
                    Route::post('sos', [AlertController::class, 'triggerSos']);
                    Route::post('{alertId}/acknowledge', [AlertController::class, 'acknowledge']);
                    Route::post('{alertId}/cancel', [AlertController::class, 'cancelSos']);
                });

                // Places & Geofencing
                Route::prefix('places')->group(function () {
                    Route::get('/', [PlaceController::class, 'index']);
                    Route::post('/', [PlaceController::class, 'store']);
                    Route::put('{placeId}', [PlaceController::class, 'update']);
                    Route::delete('{placeId}', [PlaceController::class, 'destroy']);
                    Route::post('check-geofence', [PlaceController::class, 'checkGeofence']);
                });

                // WebRTC Calling
                Route::prefix('calls')->group(function () {
                    Route::post('initiate', [CallController::class, 'initiate']);
                });
            });
        });

        // WebRTC Signaling Relays
        Route::prefix('calls/{callId}')->group(function () {
            Route::post('signal', [CallController::class, 'signal']);
            Route::post('end', [CallController::class, 'end']);
        });
    });
});
