-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 23, 2026 at 11:03 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `marlink_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `alerts`
--

CREATE TABLE `alerts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `room_id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` bigint(20) UNSIGNED NOT NULL,
  `target_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `alert_type` enum('attention','meet_here','leaving','arrived','check_on_me','sos') NOT NULL,
  `status` enum('active','acknowledged','cancelled') NOT NULL DEFAULT 'active',
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `acknowledged_at` timestamp NULL DEFAULT NULL,
  `acknowledged_by` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `alerts`
--

INSERT INTO `alerts` (`id`, `room_id`, `sender_id`, `target_user_id`, `alert_type`, `status`, `latitude`, `longitude`, `metadata`, `acknowledged_at`, `acknowledged_by`, `created_at`, `updated_at`) VALUES
(1, 1, 3, NULL, 'sos', 'active', 6.2276934, 125.0617882, '{\"emergency\":true,\"device\":\"MarLink Mobile\"}', NULL, NULL, '2026-09-22 16:25:50', '2026-09-22 16:25:50'),
(2, 1, 3, NULL, 'attention', 'active', 6.2276934, 125.0617882, NULL, NULL, NULL, '2026-09-22 16:25:57', '2026-09-22 16:25:57'),
(3, 1, 4, NULL, 'sos', 'active', 6.3076654, 124.9732409, '{\"emergency\":true,\"device\":\"MarLink Mobile\"}', NULL, NULL, '2026-09-23 01:06:55', '2026-09-23 01:06:55'),
(4, 1, 1, NULL, 'sos', 'active', 6.3076490, 124.9733434, '{\"emergency\":true,\"device\":\"MarLink Mobile\"}', NULL, NULL, '2026-09-23 03:48:18', '2026-09-23 03:48:18'),
(5, 1, 1, NULL, 'attention', 'active', 6.3076490, 124.9733434, NULL, NULL, NULL, '2026-09-23 03:48:24', '2026-09-23 03:48:24'),
(6, 1, 1, NULL, 'sos', 'active', 6.3076548, 124.9732447, '{\"emergency\":true,\"device\":\"MarLink Mobile\"}', NULL, NULL, '2026-09-23 06:08:11', '2026-09-23 06:08:11');

-- --------------------------------------------------------

--
-- Table structure for table `calls`
--

CREATE TABLE `calls` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `room_id` bigint(20) UNSIGNED NOT NULL,
  `initiator_id` bigint(20) UNSIGNED NOT NULL,
  `call_type` enum('voice','video') NOT NULL DEFAULT 'voice',
  `status` enum('calling','ringing','active','ended','rejected','failed') NOT NULL DEFAULT 'calling',
  `started_at` timestamp NULL DEFAULT NULL,
  `ended_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `calls`
--

INSERT INTO `calls` (`id`, `room_id`, `initiator_id`, `call_type`, `status`, `started_at`, `ended_at`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'voice', 'ended', '2026-09-23 04:33:03', '2026-09-23 04:33:05', '2026-09-23 04:33:03', '2026-09-23 04:33:05'),
(2, 1, 1, 'voice', 'ended', '2026-09-23 04:52:31', '2026-09-23 04:52:48', '2026-09-23 04:52:31', '2026-09-23 04:52:48'),
(3, 1, 1, 'video', 'ended', '2026-09-23 04:52:51', '2026-09-23 04:53:12', '2026-09-23 04:52:51', '2026-09-23 04:53:12'),
(4, 1, 1, 'video', 'ended', '2026-09-23 04:53:14', '2026-09-23 04:53:18', '2026-09-23 04:53:14', '2026-09-23 04:53:18'),
(5, 1, 1, 'voice', 'ended', '2026-09-23 06:10:49', '2026-09-23 06:10:58', '2026-09-23 06:10:49', '2026-09-23 06:10:58'),
(6, 1, 1, 'video', 'ended', '2026-09-23 06:11:00', '2026-09-23 06:11:23', '2026-09-23 06:11:00', '2026-09-23 06:11:23'),
(7, 1, 1, 'video', 'ended', '2026-09-23 06:11:25', '2026-09-23 06:11:39', '2026-09-23 06:11:25', '2026-09-23 06:11:39'),
(8, 1, 1, 'video', 'ended', '2026-09-23 06:11:42', '2026-09-23 06:12:02', '2026-09-23 06:11:42', '2026-09-23 06:12:02'),
(9, 1, 1, 'video', 'ended', '2026-09-23 06:12:05', '2026-09-23 06:13:02', '2026-09-23 06:12:05', '2026-09-23 06:13:02'),
(10, 1, 1, 'video', 'ended', '2026-09-23 06:58:57', '2026-09-23 06:59:08', '2026-09-23 06:58:57', '2026-09-23 06:59:08'),
(11, 1, 1, 'voice', 'ended', '2026-09-23 06:59:10', '2026-09-23 07:00:57', '2026-09-23 06:59:10', '2026-09-23 07:00:57'),
(12, 1, 1, 'video', 'ended', '2026-09-23 07:01:02', '2026-09-23 07:01:04', '2026-09-23 07:01:02', '2026-09-23 07:01:04'),
(13, 1, 1, 'voice', 'ended', '2026-09-23 07:01:51', '2026-09-23 07:02:07', '2026-09-23 07:01:51', '2026-09-23 07:02:07');

-- --------------------------------------------------------

--
-- Table structure for table `call_participants`
--

CREATE TABLE `call_participants` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `call_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('ringing','joined','left','declined') NOT NULL DEFAULT 'ringing',
  `joined_at` timestamp NULL DEFAULT NULL,
  `left_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `call_participants`
--

INSERT INTO `call_participants` (`id`, `call_id`, `user_id`, `status`, `joined_at`, `left_at`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'left', '2026-09-23 04:33:04', '2026-09-23 04:33:05', '2026-09-23 04:33:03', '2026-09-23 04:33:05'),
(2, 1, 2, 'left', NULL, '2026-09-23 04:33:05', '2026-09-23 04:33:03', '2026-09-23 04:33:05'),
(3, 1, 3, 'left', NULL, '2026-09-23 04:33:05', '2026-09-23 04:33:03', '2026-09-23 04:33:05'),
(4, 1, 4, 'left', NULL, '2026-09-23 04:33:05', '2026-09-23 04:33:03', '2026-09-23 04:33:05'),
(6, 2, 1, 'left', '2026-09-23 04:52:31', '2026-09-23 04:52:48', '2026-09-23 04:52:31', '2026-09-23 04:52:48'),
(7, 2, 2, 'left', NULL, '2026-09-23 04:52:48', '2026-09-23 04:52:31', '2026-09-23 04:52:48'),
(8, 2, 3, 'left', NULL, '2026-09-23 04:52:48', '2026-09-23 04:52:31', '2026-09-23 04:52:48'),
(9, 2, 4, 'left', NULL, '2026-09-23 04:52:48', '2026-09-23 04:52:31', '2026-09-23 04:52:48'),
(10, 3, 1, 'left', '2026-09-23 04:52:51', '2026-09-23 04:53:12', '2026-09-23 04:52:51', '2026-09-23 04:53:12'),
(11, 3, 2, 'left', NULL, '2026-09-23 04:53:12', '2026-09-23 04:52:51', '2026-09-23 04:53:12'),
(12, 3, 3, 'left', NULL, '2026-09-23 04:53:12', '2026-09-23 04:52:51', '2026-09-23 04:53:12'),
(13, 3, 4, 'left', NULL, '2026-09-23 04:53:12', '2026-09-23 04:52:51', '2026-09-23 04:53:12'),
(14, 4, 1, 'left', '2026-09-23 04:53:14', '2026-09-23 04:53:18', '2026-09-23 04:53:14', '2026-09-23 04:53:18'),
(15, 4, 2, 'left', NULL, '2026-09-23 04:53:18', '2026-09-23 04:53:14', '2026-09-23 04:53:18'),
(16, 4, 3, 'left', NULL, '2026-09-23 04:53:18', '2026-09-23 04:53:14', '2026-09-23 04:53:18'),
(17, 4, 4, 'left', NULL, '2026-09-23 04:53:18', '2026-09-23 04:53:14', '2026-09-23 04:53:18'),
(18, 5, 1, 'left', '2026-09-23 06:10:49', '2026-09-23 06:10:58', '2026-09-23 06:10:49', '2026-09-23 06:10:58'),
(19, 5, 2, 'left', NULL, '2026-09-23 06:10:58', '2026-09-23 06:10:49', '2026-09-23 06:10:58'),
(20, 5, 3, 'left', NULL, '2026-09-23 06:10:58', '2026-09-23 06:10:49', '2026-09-23 06:10:58'),
(21, 5, 4, 'left', NULL, '2026-09-23 06:10:58', '2026-09-23 06:10:49', '2026-09-23 06:10:58'),
(22, 6, 1, 'left', '2026-09-23 06:11:00', '2026-09-23 06:11:23', '2026-09-23 06:11:00', '2026-09-23 06:11:23'),
(23, 6, 2, 'left', NULL, '2026-09-23 06:11:23', '2026-09-23 06:11:00', '2026-09-23 06:11:23'),
(24, 6, 3, 'left', NULL, '2026-09-23 06:11:23', '2026-09-23 06:11:00', '2026-09-23 06:11:23'),
(25, 6, 4, 'left', NULL, '2026-09-23 06:11:23', '2026-09-23 06:11:00', '2026-09-23 06:11:23'),
(26, 7, 1, 'left', '2026-09-23 06:11:25', '2026-09-23 06:11:39', '2026-09-23 06:11:25', '2026-09-23 06:11:39'),
(27, 7, 2, 'left', NULL, '2026-09-23 06:11:39', '2026-09-23 06:11:25', '2026-09-23 06:11:39'),
(28, 7, 3, 'left', NULL, '2026-09-23 06:11:39', '2026-09-23 06:11:25', '2026-09-23 06:11:39'),
(29, 7, 4, 'left', NULL, '2026-09-23 06:11:39', '2026-09-23 06:11:25', '2026-09-23 06:11:39'),
(30, 8, 1, 'left', '2026-09-23 06:11:42', '2026-09-23 06:12:02', '2026-09-23 06:11:42', '2026-09-23 06:12:02'),
(31, 8, 2, 'left', NULL, '2026-09-23 06:12:02', '2026-09-23 06:11:42', '2026-09-23 06:12:02'),
(32, 8, 3, 'left', NULL, '2026-09-23 06:12:02', '2026-09-23 06:11:42', '2026-09-23 06:12:02'),
(33, 8, 4, 'left', NULL, '2026-09-23 06:12:02', '2026-09-23 06:11:42', '2026-09-23 06:12:02'),
(34, 9, 1, 'left', '2026-09-23 06:12:05', '2026-09-23 06:12:59', '2026-09-23 06:12:05', '2026-09-23 06:12:59'),
(35, 9, 2, 'left', NULL, '2026-09-23 06:12:59', '2026-09-23 06:12:05', '2026-09-23 06:12:59'),
(36, 9, 3, 'left', NULL, '2026-09-23 06:12:59', '2026-09-23 06:12:05', '2026-09-23 06:12:59'),
(37, 9, 4, 'left', NULL, '2026-09-23 06:12:59', '2026-09-23 06:12:05', '2026-09-23 06:12:59'),
(38, 10, 1, 'left', '2026-09-23 06:58:57', '2026-09-23 06:59:08', '2026-09-23 06:58:57', '2026-09-23 06:59:08'),
(39, 10, 2, 'left', NULL, '2026-09-23 06:59:08', '2026-09-23 06:58:57', '2026-09-23 06:59:08'),
(40, 10, 3, 'left', NULL, '2026-09-23 06:59:08', '2026-09-23 06:58:57', '2026-09-23 06:59:08'),
(41, 10, 4, 'left', NULL, '2026-09-23 06:59:08', '2026-09-23 06:58:57', '2026-09-23 06:59:08'),
(42, 11, 1, 'left', '2026-09-23 06:59:10', '2026-09-23 07:00:57', '2026-09-23 06:59:10', '2026-09-23 07:00:57'),
(43, 11, 2, 'left', NULL, '2026-09-23 07:00:57', '2026-09-23 06:59:10', '2026-09-23 07:00:57'),
(44, 11, 3, 'left', NULL, '2026-09-23 07:00:57', '2026-09-23 06:59:10', '2026-09-23 07:00:57'),
(45, 11, 4, 'left', NULL, '2026-09-23 07:00:57', '2026-09-23 06:59:10', '2026-09-23 07:00:57'),
(46, 12, 1, 'left', '2026-09-23 07:01:02', '2026-09-23 07:01:04', '2026-09-23 07:01:02', '2026-09-23 07:01:04'),
(47, 12, 2, 'left', NULL, '2026-09-23 07:01:04', '2026-09-23 07:01:02', '2026-09-23 07:01:04'),
(48, 12, 3, 'left', NULL, '2026-09-23 07:01:04', '2026-09-23 07:01:02', '2026-09-23 07:01:04'),
(49, 12, 4, 'left', NULL, '2026-09-23 07:01:04', '2026-09-23 07:01:02', '2026-09-23 07:01:04'),
(50, 13, 1, 'left', '2026-09-23 07:01:51', '2026-09-23 07:02:07', '2026-09-23 07:01:51', '2026-09-23 07:02:07'),
(51, 13, 2, 'left', NULL, '2026-09-23 07:02:07', '2026-09-23 07:01:51', '2026-09-23 07:02:07');

-- --------------------------------------------------------

--
-- Table structure for table `device_tokens`
--

CREATE TABLE `device_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token` varchar(500) NOT NULL,
  `device_type` enum('android','ios') NOT NULL DEFAULT 'android',
  `last_used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `geofence_events`
--

CREATE TABLE `geofence_events` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `place_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `event_type` enum('enter','leave') NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `triggered_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `locations`
--

CREATE TABLE `locations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `accuracy` float DEFAULT NULL,
  `altitude` float DEFAULT NULL,
  `speed` float DEFAULT NULL,
  `heading` float DEFAULT NULL,
  `battery_pct` tinyint(3) UNSIGNED DEFAULT NULL,
  `is_moving` tinyint(1) NOT NULL DEFAULT 0,
  `recorded_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `locations`
--

INSERT INTO `locations` (`id`, `user_id`, `latitude`, `longitude`, `accuracy`, `altitude`, `speed`, `heading`, `battery_pct`, `is_moving`, `recorded_at`, `created_at`, `updated_at`) VALUES
(1, 1, 6.3076379, 124.9733526, 32.707, 481.8, 0.791337, 101.643, 77, 0, '2026-09-23 07:31:12', '2026-09-22 14:44:31', '2026-09-23 07:31:12'),
(2, 2, 14.5580000, 121.0195000, 6, NULL, 0, 0, 92, 0, '2026-09-22 14:44:31', '2026-09-22 14:44:31', '2026-09-22 14:44:31'),
(3, 3, 6.2276992, 125.0618086, 18.444, 403.4, 3.4528, 234.195, 27, 1, '2026-09-22 16:36:23', '2026-09-22 14:44:31', '2026-09-22 16:36:23'),
(8, 4, 6.3076579, 124.9732431, 224.261, 481.8, 0, 0, 74, 0, '2026-09-23 01:43:48', '2026-09-23 01:05:01', '2026-09-23 01:43:48');

-- --------------------------------------------------------

--
-- Table structure for table `location_history`
--

CREATE TABLE `location_history` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `room_id` bigint(20) UNSIGNED DEFAULT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `speed` float DEFAULT NULL,
  `heading` float DEFAULT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `location_history`
--

INSERT INTO `location_history` (`id`, `user_id`, `room_id`, `latitude`, `longitude`, `speed`, `heading`, `recorded_at`, `created_at`, `updated_at`) VALUES
(1, 3, NULL, 6.2276934, 125.0617882, 0, 0, '2026-09-22 16:25:07', '2026-09-22 16:25:07', '2026-09-22 16:25:07'),
(2, 3, NULL, 6.2276774, 125.0620335, 0, 0, '2026-09-22 16:32:50', '2026-09-22 16:32:50', '2026-09-22 16:32:50'),
(3, 3, NULL, 6.2276911, 125.0618848, 1.39324, 260.576, '2026-09-22 16:33:00', '2026-09-22 16:33:00', '2026-09-22 16:33:00'),
(4, 3, NULL, 6.2276992, 125.0618086, 3.4528, 234.195, '2026-09-22 16:36:23', '2026-09-22 16:36:23', '2026-09-22 16:36:23'),
(5, 4, NULL, 6.3076797, 124.9732421, 0, 0, '2026-09-23 01:05:01', '2026-09-23 01:05:01', '2026-09-23 01:05:01'),
(6, 4, NULL, 6.3053810, 124.9759817, 0, 0, '2026-09-23 01:05:19', '2026-09-23 01:05:19', '2026-09-23 01:05:19'),
(7, 4, NULL, 6.3076722, 124.9732439, 0, 0, '2026-09-23 01:41:59', '2026-09-23 01:41:59', '2026-09-23 01:41:59'),
(8, 4, NULL, 6.3076329, 124.9733259, 0, 0, '2026-09-23 01:42:19', '2026-09-23 01:42:19', '2026-09-23 01:42:19'),
(9, 4, NULL, 6.3076782, 124.9732316, 0, 0, '2026-09-23 01:42:29', '2026-09-23 01:42:29', '2026-09-23 01:42:29'),
(10, 4, NULL, 6.3076146, 124.9733504, 0, 0, '2026-09-23 01:42:50', '2026-09-23 01:42:50', '2026-09-23 01:42:50'),
(11, 4, NULL, 6.3076691, 124.9732393, 0, 0, '2026-09-23 01:43:01', '2026-09-23 01:43:01', '2026-09-23 01:43:01'),
(12, 4, NULL, 6.3068578, 124.9749484, 0, 0, '2026-09-23 01:43:37', '2026-09-23 01:43:37', '2026-09-23 01:43:37'),
(13, 4, NULL, 6.3076579, 124.9732431, 0, 0, '2026-09-23 01:43:48', '2026-09-23 01:43:48', '2026-09-23 01:43:48'),
(14, 1, NULL, 6.3124863, 124.9708151, 0, 0, '2026-09-23 01:45:02', '2026-09-23 01:45:02', '2026-09-23 01:45:02'),
(15, 1, NULL, 6.3076411, 124.9732862, 0, 90, '2026-09-23 01:45:13', '2026-09-23 01:45:13', '2026-09-23 01:45:13'),
(16, 1, NULL, 6.3076788, 124.9732357, 0, 0, '2026-09-23 01:54:19', '2026-09-23 01:54:19', '2026-09-23 01:54:19'),
(17, 1, NULL, 6.3076360, 124.9733330, 1.77863, 90, '2026-09-23 01:58:49', '2026-09-23 01:58:49', '2026-09-23 01:58:49'),
(18, 1, NULL, 6.3076806, 124.9732392, 0, 0, '2026-09-23 01:59:25', '2026-09-23 01:59:25', '2026-09-23 01:59:25'),
(19, 1, NULL, 6.3076419, 124.9733298, 0, 0, '2026-09-23 02:03:04', '2026-09-23 02:03:04', '2026-09-23 02:03:04'),
(20, 1, NULL, 6.3076740, 124.9732405, 0, 0, '2026-09-23 02:03:14', '2026-09-23 02:03:14', '2026-09-23 02:03:14'),
(21, 1, NULL, 6.3076320, 124.9733211, 0, 0, '2026-09-23 02:11:24', '2026-09-23 02:11:24', '2026-09-23 02:11:24'),
(22, 1, NULL, 6.3076691, 124.9732353, 0, 0, '2026-09-23 02:13:09', '2026-09-23 02:13:09', '2026-09-23 02:13:09'),
(23, 1, NULL, 6.3076222, 124.9733111, 0, 0, '2026-09-23 04:52:00', '2026-09-23 04:52:00', '2026-09-23 04:52:00'),
(24, 1, NULL, 6.3076927, 124.9731553, 3.76663, 81.9245, '2026-09-23 04:52:18', '2026-09-23 04:52:18', '2026-09-23 04:52:18'),
(25, 1, NULL, 6.3075483, 124.9732980, 2.14012, 89.8373, '2026-09-23 04:52:28', '2026-09-23 04:52:28', '2026-09-23 04:52:28'),
(26, 1, NULL, 6.3076418, 124.9733166, 0.953524, 80.3339, '2026-09-23 04:52:39', '2026-09-23 04:52:39', '2026-09-23 04:52:39'),
(27, 1, NULL, 6.3076210, 124.9732272, 7.38396, 218.121, '2026-09-23 04:53:19', '2026-09-23 04:53:19', '2026-09-23 04:53:19'),
(28, 1, NULL, 6.3076644, 124.9733235, 3.31955, 27.565, '2026-09-23 04:54:46', '2026-09-23 04:54:46', '2026-09-23 04:54:46'),
(29, 1, NULL, 6.3076302, 124.9732390, 0.710379, 247.135, '2026-09-23 04:55:34', '2026-09-23 04:55:34', '2026-09-23 04:55:34'),
(30, 1, NULL, 6.3076592, 124.9734102, 2.08452, 54.7015, '2026-09-23 04:56:30', '2026-09-23 04:56:30', '2026-09-23 04:56:30'),
(31, 1, NULL, 6.3077400, 124.9733393, 12.156, 18.4863, '2026-09-23 04:56:40', '2026-09-23 04:56:40', '2026-09-23 04:56:40'),
(32, 1, NULL, 6.3077485, 124.9731268, 5.46963, 295.289, '2026-09-23 04:56:49', '2026-09-23 04:56:49', '2026-09-23 04:56:49'),
(33, 1, NULL, 6.3075895, 124.9732930, 2.36895, 180.412, '2026-09-23 04:57:00', '2026-09-23 04:57:00', '2026-09-23 04:57:00'),
(34, 1, NULL, 6.3076604, 124.9732159, 0.88543, 89.9676, '2026-09-23 04:58:16', '2026-09-23 04:58:16', '2026-09-23 04:58:16'),
(35, 1, NULL, 6.3076381, 124.9733200, 4.34776, 90.0803, '2026-09-23 04:59:05', '2026-09-23 04:59:05', '2026-09-23 04:59:05'),
(36, 1, NULL, 6.3076548, 124.9732447, 0, 0, '2026-09-23 06:08:05', '2026-09-23 06:08:05', '2026-09-23 06:08:05'),
(37, 1, NULL, 6.3076648, 124.9733501, 0.832327, 84.5431, '2026-09-23 06:08:36', '2026-09-23 06:08:36', '2026-09-23 06:08:36'),
(38, 1, NULL, 6.3076574, 124.9732337, 7.47131, 277.036, '2026-09-23 06:09:05', '2026-09-23 06:09:05', '2026-09-23 06:09:05'),
(39, 1, NULL, 6.3074694, 124.9731626, 5.84552, 206.381, '2026-09-23 06:09:18', '2026-09-23 06:09:18', '2026-09-23 06:09:18'),
(40, 1, NULL, 6.3076427, 124.9733583, 6.89638, 110.642, '2026-09-23 06:09:30', '2026-09-23 06:09:30', '2026-09-23 06:09:30'),
(41, 1, NULL, 6.3076604, 124.9732522, 2.01803, 281.329, '2026-09-23 06:11:08', '2026-09-23 06:11:08', '2026-09-23 06:11:08'),
(42, 1, NULL, 6.3076675, 124.9733914, 4.58399, 76.8521, '2026-09-23 06:11:41', '2026-09-23 06:11:41', '2026-09-23 06:11:41'),
(43, 1, NULL, 6.3076449, 124.9732935, 3.47142, 256.895, '2026-09-23 06:12:08', '2026-09-23 06:12:08', '2026-09-23 06:12:08'),
(44, 1, NULL, 6.3075591, 124.9733350, 2.90485, 163.551, '2026-09-23 06:12:58', '2026-09-23 06:12:58', '2026-09-23 06:12:58'),
(45, 1, NULL, 6.3076534, 124.9732731, 0, 0, '2026-09-23 06:21:45', '2026-09-23 06:21:45', '2026-09-23 06:21:45'),
(46, 1, NULL, 6.3076692, 124.9731413, 4.18632, 280.796, '2026-09-23 06:25:15', '2026-09-23 06:25:15', '2026-09-23 06:25:15'),
(47, 1, NULL, 6.3076255, 124.9733925, 5.30294, 136.96, '2026-09-23 06:25:30', '2026-09-23 06:25:30', '2026-09-23 06:25:30'),
(48, 1, NULL, 6.3075163, 124.9733246, 2.50605, 264.876, '2026-09-23 06:25:53', '2026-09-23 06:25:53', '2026-09-23 06:25:53'),
(49, 1, NULL, 6.3076016, 124.9732184, 4.52271, 246.249, '2026-09-23 06:25:59', '2026-09-23 06:25:59', '2026-09-23 06:25:59'),
(50, 1, NULL, 6.3076785, 124.9732700, 0.723971, 289.733, '2026-09-23 06:26:10', '2026-09-23 06:26:10', '2026-09-23 06:26:10'),
(51, 1, NULL, 6.3076799, 124.9733728, 0, 0, '2026-09-23 06:41:42', '2026-09-23 06:41:42', '2026-09-23 06:41:42'),
(52, 1, NULL, 6.3076139, 124.9733870, 0, 0, '2026-09-23 06:56:19', '2026-09-23 06:56:19', '2026-09-23 06:56:19'),
(53, 1, NULL, 6.3076534, 124.9732790, 1.31124, 262.442, '2026-09-23 06:58:16', '2026-09-23 06:58:16', '2026-09-23 06:58:16'),
(54, 1, NULL, 6.3076606, 124.9733696, 2.0236, 108.256, '2026-09-23 07:06:54', '2026-09-23 07:06:54', '2026-09-23 07:06:54'),
(55, 1, NULL, 6.3076731, 124.9732793, 1.19998, 116.481, '2026-09-23 07:08:15', '2026-09-23 07:08:15', '2026-09-23 07:08:15'),
(56, 1, NULL, 6.3076495, 124.9732710, 0.135687, 0, '2026-09-23 07:21:31', '2026-09-23 07:21:31', '2026-09-23 07:21:31'),
(57, 1, NULL, 6.3076912, 124.9732924, 0.700243, 89.9804, '2026-09-23 07:21:39', '2026-09-23 07:21:39', '2026-09-23 07:21:39'),
(58, 1, NULL, 6.3077528, 124.9732883, 0.663103, 82.966, '2026-09-23 07:21:42', '2026-09-23 07:21:42', '2026-09-23 07:21:42'),
(59, 1, NULL, 6.3077708, 124.9732964, 0.754756, 22.9659, '2026-09-23 07:21:52', '2026-09-23 07:21:52', '2026-09-23 07:21:52'),
(60, 1, NULL, 6.3077858, 124.9733015, 0.580923, 10.9679, '2026-09-23 07:22:03', '2026-09-23 07:22:03', '2026-09-23 07:22:03'),
(61, 1, NULL, 6.3077886, 124.9732959, 0.595953, 1.84308, '2026-09-23 07:22:14', '2026-09-23 07:22:14', '2026-09-23 07:22:14'),
(62, 1, NULL, 6.3077842, 124.9732949, 0.553362, 17.8548, '2026-09-23 07:22:24', '2026-09-23 07:22:24', '2026-09-23 07:22:24'),
(63, 1, NULL, 6.3077811, 124.9732951, 1.01604, 89.33, '2026-09-23 07:22:35', '2026-09-23 07:22:35', '2026-09-23 07:22:35'),
(64, 1, NULL, 6.3077690, 124.9733031, 1.07469, 129.248, '2026-09-23 07:22:45', '2026-09-23 07:22:45', '2026-09-23 07:22:45'),
(65, 1, NULL, 6.3077429, 124.9733110, 0.992117, 160.462, '2026-09-23 07:22:56', '2026-09-23 07:22:56', '2026-09-23 07:22:56'),
(66, 1, NULL, 6.3077256, 124.9732969, 1.91915, 173.138, '2026-09-23 07:23:06', '2026-09-23 07:23:06', '2026-09-23 07:23:06'),
(67, 1, NULL, 6.3077151, 124.9732967, 0.953071, 181.412, '2026-09-23 07:23:17', '2026-09-23 07:23:17', '2026-09-23 07:23:17'),
(68, 1, NULL, 6.3077074, 124.9733103, 0.972639, 169.764, '2026-09-23 07:23:28', '2026-09-23 07:23:28', '2026-09-23 07:23:28'),
(69, 1, NULL, 6.3077048, 124.9733064, 1.00673, 90.3523, '2026-09-23 07:23:38', '2026-09-23 07:23:38', '2026-09-23 07:23:38'),
(70, 1, NULL, 6.3077213, 124.9732982, 0.732741, 333.102, '2026-09-23 07:23:53', '2026-09-23 07:23:53', '2026-09-23 07:23:53'),
(71, 1, NULL, 6.3076623, 124.9732554, 0.157884, 0, '2026-09-23 07:30:51', '2026-09-23 07:30:51', '2026-09-23 07:30:51'),
(72, 1, NULL, 6.3076576, 124.9732552, 0.171073, 0, '2026-09-23 07:31:01', '2026-09-23 07:31:01', '2026-09-23 07:31:01'),
(73, 1, NULL, 6.3076379, 124.9733526, 0.791337, 101.643, '2026-09-23 07:31:12', '2026-09-23 07:31:12', '2026-09-23 07:31:12');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `room_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `reply_to_id` bigint(20) UNSIGNED DEFAULT NULL,
  `message_type` enum('text','image','location') NOT NULL DEFAULT 'text',
  `content` text DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `location_label` varchar(255) DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `room_id`, `user_id`, `reply_to_id`, `message_type`, `content`, `latitude`, `longitude`, `location_label`, `is_deleted`, `created_at`, `updated_at`) VALUES
(1, 1, 1, NULL, 'text', 'Welcome to MarLink Family room! Keep your location sharing active.', NULL, NULL, NULL, 0, '2026-09-22 14:44:31', '2026-09-22 14:44:31'),
(2, 1, 3, NULL, 'text', 'Asa namo', NULL, NULL, NULL, 0, '2026-09-22 16:24:27', '2026-09-22 16:24:27'),
(3, 1, 3, NULL, 'location', '🚨 EMERGENCY SOS TRIGGERED by John Santos! Please check their location immediately!', 6.2276934, 125.0617882, 'SOS EMERGENCY LOCATION', 0, '2026-09-22 16:25:50', '2026-09-22 16:25:50'),
(4, 1, 3, NULL, 'location', NULL, 6.2276934, 125.0617882, 'My Current Location', 0, '2026-09-22 16:26:47', '2026-09-22 16:26:47'),
(5, 1, 3, NULL, 'text', 'Asa na mi', NULL, NULL, NULL, 0, '2026-09-22 16:28:43', '2026-09-22 16:28:43'),
(6, 1, 3, NULL, 'text', 'Reply mk', NULL, NULL, NULL, 0, '2026-09-22 16:28:46', '2026-09-22 16:28:46'),
(7, 1, 3, NULL, 'location', NULL, 6.2276934, 125.0617882, 'My Current Location', 0, '2026-09-22 16:29:54', '2026-09-22 16:29:54'),
(8, 1, 1, NULL, 'image', 'Test upload from script', NULL, NULL, NULL, 0, '2026-09-22 16:50:38', '2026-09-22 16:50:38'),
(9, 1, 4, NULL, 'image', 'http://192.168.4.43:8000/uploads/img_20260923_010622_8ffeed9b06b6.jpg', NULL, NULL, NULL, 0, '2026-09-23 01:06:22', '2026-09-23 01:06:22'),
(10, 1, 4, NULL, 'text', '🟢 Started sharing live location with room.', NULL, NULL, NULL, 0, '2026-09-23 01:06:32', '2026-09-23 01:06:32'),
(11, 1, 4, NULL, 'location', NULL, 6.3076654, 124.9732409, 'My Current Location', 0, '2026-09-23 01:06:40', '2026-09-23 01:06:40'),
(12, 1, 4, NULL, 'location', '🚨 EMERGENCY SOS TRIGGERED by Loleng Testing! Please check their location immediately!', 6.3076654, 124.9732409, 'SOS EMERGENCY LOCATION', 0, '2026-09-23 01:06:55', '2026-09-23 01:06:55'),
(13, 1, 4, NULL, 'image', 'http://192.168.4.43:8000/uploads/img_20260923_010828_7d2998e81113.jpg', NULL, NULL, NULL, 0, '2026-09-23 01:08:28', '2026-09-23 01:08:28'),
(14, 1, 1, NULL, 'location', '🚨 EMERGENCY SOS TRIGGERED by Mark Lawrence! Please check their location immediately!', 6.3076490, 124.9733434, 'SOS EMERGENCY LOCATION', 0, '2026-09-23 03:48:18', '2026-09-23 03:48:18'),
(15, 1, 1, NULL, 'location', '🚨 EMERGENCY SOS TRIGGERED by Mark Lawrence! Please check their location immediately!', 6.3076548, 124.9732447, 'SOS EMERGENCY LOCATION', 0, '2026-09-23 06:08:11', '2026-09-23 06:08:11'),
(16, 1, 1, NULL, '', 'Cancelled video call', NULL, NULL, NULL, 0, '2026-09-23 06:59:08', '2026-09-23 06:59:08'),
(17, 1, 1, NULL, '', 'Cancelled call', NULL, NULL, NULL, 0, '2026-09-23 07:00:57', '2026-09-23 07:00:57'),
(18, 1, 1, NULL, '', 'Cancelled video call', NULL, NULL, NULL, 0, '2026-09-23 07:01:04', '2026-09-23 07:01:04'),
(19, 1, 1, NULL, '', 'Cancelled call', NULL, NULL, NULL, 0, '2026-09-23 07:02:07', '2026-09-23 07:02:07');

-- --------------------------------------------------------

--
-- Table structure for table `message_attachments`
--

CREATE TABLE `message_attachments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `message_id` bigint(20) UNSIGNED NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `file_url` varchar(255) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_size` bigint(20) UNSIGNED NOT NULL,
  `mime_type` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `message_attachments`
--

INSERT INTO `message_attachments` (`id`, `message_id`, `file_path`, `file_url`, `file_name`, `file_size`, `mime_type`, `created_at`, `updated_at`) VALUES
(1, 8, 'C:\\AndriodStudioProjects\\marlink\\marlink_api/uploads/img_20260922_165038_559fddfadbf1.jpg', 'http://127.0.0.1:8000/uploads/img_20260922_165038_559fddfadbf1.jpg', 'img_20260922_165038_559fddfadbf1.jpg', 31, 'image/jpeg', '2026-09-22 16:50:38', '2026-09-22 16:50:38'),
(2, 9, 'C:\\AndriodStudioProjects\\marlink\\marlink_api/uploads/img_20260923_010622_8ffeed9b06b6.jpg', 'http://192.168.4.43:8000/uploads/img_20260923_010622_8ffeed9b06b6.jpg', 'img_20260923_010622_8ffeed9b06b6.jpg', 116013, 'image/jpeg', '2026-09-23 01:06:22', '2026-09-23 01:06:22'),
(3, 13, 'C:\\AndriodStudioProjects\\marlink\\marlink_api/uploads/img_20260923_010828_7d2998e81113.jpg', 'http://192.168.4.43:8000/uploads/img_20260923_010828_7d2998e81113.jpg', 'img_20260923_010828_7d2998e81113.jpg', 150963, 'image/jpeg', '2026-09-23 01:08:28', '2026-09-23 01:08:28');

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(1, 'AppModelsUser', 1, 'mobile', 'ab9725961e80a9acec0b10ffda241543e8c8ecc7ed6ada1ed88f50a1b642d204', '[\"*\"]', NULL, NULL, '2026-09-22 15:19:04', '2026-09-22 15:19:04'),
(3, 'AppModelsUser', 1, 'mobile', '79547a90b17d7f252ac7902925c5424001050d27411519acbce38c85a987ac19', '[\"*\"]', NULL, NULL, '2026-09-22 16:41:53', '2026-09-22 16:41:53'),
(4, 'AppModelsUser', 1, 'mobile', 'b998eca8fb4e0c02483a8a074d507b6c098c57a3ed80adcfebf587d0edab34ea', '[\"*\"]', NULL, NULL, '2026-09-22 16:50:37', '2026-09-22 16:50:37'),
(6, 'AppModelsUser', 3, 'mobile', '65304e4cdf86fe61443f533b0e33b9aa3b68ced5873bcfe6c2c1838bcf280c1e', '[\"*\"]', NULL, NULL, '2026-09-22 17:14:21', '2026-09-22 17:14:21'),
(7, 'AppModelsUser', 4, 'mobile', '89454008d0b5d225d004ff39556db63f109a047169e241a8b9fc1810ac42fea2', '[\"*\"]', NULL, NULL, '2026-09-22 17:14:41', '2026-09-22 17:14:41'),
(11, 'AppModelsUser', 1, 'mobile', 'bb8d2f0d983ed2bbbbe54577275a00f8fb3c3c2263df58d55ffd2b3d3c884440', '[\"*\"]', NULL, NULL, '2026-09-23 01:44:24', '2026-09-23 01:44:24'),
(12, 'AppModelsUser', 3, 'mobile', '1a3c613bbe77e136dab2289ff57ca456b4350f1718cc408efddb0ba164adebcc', '[\"*\"]', NULL, NULL, '2026-09-23 01:57:45', '2026-09-23 01:57:45'),
(13, 'AppModelsUser', 3, 'mobile', 'af83f41d028daf462f68e7f69c0bea8d7b54761c2b934c9f19450ddf32099060', '[\"*\"]', NULL, NULL, '2026-09-23 01:58:26', '2026-09-23 01:58:26'),
(14, 'AppModelsUser', 1, 'mobile', '85ff58eee432dd00e3f08256158fba87d33b5397081769948461b4cd6842a8d1', '[\"*\"]', NULL, NULL, '2026-09-23 04:33:03', '2026-09-23 04:33:03');

-- --------------------------------------------------------

--
-- Table structure for table `places`
--

CREATE TABLE `places` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `room_id` bigint(20) UNSIGNED NOT NULL,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `icon` varchar(50) NOT NULL DEFAULT 'location_pin',
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `radius_meters` int(10) UNSIGNED NOT NULL DEFAULT 150,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `places`
--

INSERT INTO `places` (`id`, `room_id`, `created_by`, `name`, `icon`, `latitude`, `longitude`, `radius_meters`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'Home', 'home', 14.5545000, 121.0240000, 200, 1, '2026-09-22 14:44:31', '2026-09-22 14:44:31');

-- --------------------------------------------------------

--
-- Table structure for table `rooms`
--

CREATE TABLE `rooms` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(16) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `avatar_url` varchar(255) DEFAULT NULL,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rooms`
--

INSERT INTO `rooms` (`id`, `code`, `name`, `description`, `avatar_url`, `created_by`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'FAM-82K4', 'Family', 'Official family safety & location sharing group.', NULL, 1, 1, '2026-09-22 14:44:31', '2026-09-22 14:44:31'),
(2, 'MAR-B510', 'Testing', 'Charchar', NULL, 3, 1, '2026-09-22 22:59:20', '2026-09-22 22:59:20');

-- --------------------------------------------------------

--
-- Table structure for table `room_members`
--

CREATE TABLE `room_members` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `room_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `role` enum('owner','admin','member') NOT NULL DEFAULT 'member',
  `is_location_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `custom_nickname` varchar(100) DEFAULT NULL,
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `room_members`
--

INSERT INTO `room_members` (`id`, `room_id`, `user_id`, `role`, `is_location_enabled`, `custom_nickname`, `joined_at`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'owner', 1, NULL, '2026-09-22 14:44:31', '2026-09-22 14:44:31', '2026-09-22 14:44:31'),
(2, 1, 2, 'admin', 1, NULL, '2026-09-22 14:44:31', '2026-09-22 14:44:31', '2026-09-22 14:44:31'),
(3, 1, 3, 'member', 1, NULL, '2026-09-22 14:44:31', '2026-09-22 14:44:31', '2026-09-22 14:44:31'),
(4, 1, 4, 'member', 1, NULL, '2026-09-22 22:55:53', '2026-09-22 22:55:53', '2026-09-22 22:55:53'),
(5, 2, 3, 'owner', 1, NULL, '2026-09-22 22:59:20', '2026-09-22 22:59:20', '2026-09-22 22:59:20'),
(6, 2, 4, 'member', 1, NULL, '2026-09-22 23:01:07', '2026-09-22 23:01:07', '2026-09-22 23:01:07');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(150) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `username`, `email`, `phone`, `email_verified_at`, `password`, `is_active`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Mark Lawrence', 'mark', 'mark@marlink.local', '+639171234567', NULL, '$2y$12$D24hQ2vC7H9X1kE1z2E3U.j0I5Z2K7L3m4N5O6P7Q8R9S0T1U2V3W', 1, NULL, '2026-09-22 14:44:31', '2026-09-22 14:44:31'),
(2, 'Anna Lawrence', 'anna', 'anna@marlink.local', '+639179876543', NULL, '$2y$12$D24hQ2vC7H9X1kE1z2E3U.j0I5Z2K7L3m4N5O6P7Q8R9S0T1U2V3W', 1, NULL, '2026-09-22 14:44:31', '2026-09-22 14:44:31'),
(3, 'John Santos', 'john', 'john@marlink.local', '+639185551234', NULL, '$2y$10$3zESzBQ89cFwz71dgMy4i./oIRgN5Fj7AdGkhyZY8TyDkzXhlFEwy', 1, NULL, '2026-09-22 14:44:31', '2026-09-22 17:14:22'),
(4, 'Loleng Testing', 'Loleng', 'rampingmarklawrence@gmail.com', '09182256512', NULL, '$2y$10$EMIzDkb6gq/v7Xq5cKzY2OteBN6fbApPqIYdCIWleBMf7tDZYn7G2', 1, NULL, '2026-09-22 17:12:59', '2026-09-22 17:12:59');

-- --------------------------------------------------------

--
-- Table structure for table `user_profiles`
--

CREATE TABLE `user_profiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `avatar_url` varchar(255) DEFAULT NULL,
  `bio` varchar(255) DEFAULT NULL,
  `battery_pct` tinyint(3) UNSIGNED NOT NULL DEFAULT 100,
  `sharing_status` enum('on','paused','off') NOT NULL DEFAULT 'on',
  `sharing_expires_at` timestamp NULL DEFAULT NULL,
  `show_speed` tinyint(1) NOT NULL DEFAULT 1,
  `show_battery` tinyint(1) NOT NULL DEFAULT 1,
  `allow_geofence_alerts` tinyint(1) NOT NULL DEFAULT 1,
  `last_seen_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_profiles`
--

INSERT INTO `user_profiles` (`id`, `user_id`, `avatar_url`, `bio`, `battery_pct`, `sharing_status`, `sharing_expires_at`, `show_speed`, `show_battery`, `allow_geofence_alerts`, `last_seen_at`, `created_at`, `updated_at`) VALUES
(1, 1, 'http://192.168.4.43:8000/uploads/avatars/avatar_1_1790135366.png', 'Always on the move.', 77, 'on', NULL, 1, 1, 1, '2026-09-23 07:31:12', '2026-09-22 14:44:31', '2026-09-23 07:31:12'),
(2, 2, NULL, 'Graphic designer & traveler', 92, 'on', NULL, 1, 1, 1, '2026-09-22 14:44:31', '2026-09-22 14:44:31', '2026-09-22 14:44:31'),
(3, 3, NULL, 'Work & Coffee', 27, 'off', NULL, 1, 1, 1, '2026-09-22 16:36:23', '2026-09-22 14:44:31', '2026-09-23 01:58:26'),
(4, 4, NULL, NULL, 74, 'off', NULL, 1, 1, 1, '2026-09-23 01:43:48', '2026-09-22 17:12:59', '2026-09-23 01:43:48');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `alerts`
--
ALTER TABLE `alerts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `alerts_room_status_index` (`room_id`,`status`),
  ADD KEY `alerts_sender_created_index` (`sender_id`,`created_at`),
  ADD KEY `alerts_target_user_id_foreign` (`target_user_id`),
  ADD KEY `alerts_acknowledged_by_foreign` (`acknowledged_by`);

--
-- Indexes for table `calls`
--
ALTER TABLE `calls`
  ADD PRIMARY KEY (`id`),
  ADD KEY `calls_room_status_index` (`room_id`,`status`),
  ADD KEY `calls_initiator_id_foreign` (`initiator_id`);

--
-- Indexes for table `call_participants`
--
ALTER TABLE `call_participants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `call_participants_call_user_unique` (`call_id`,`user_id`),
  ADD KEY `call_participants_user_id_foreign` (`user_id`);

--
-- Indexes for table `device_tokens`
--
ALTER TABLE `device_tokens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `device_tokens_user_id_foreign` (`user_id`);

--
-- Indexes for table `geofence_events`
--
ALTER TABLE `geofence_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `geofence_events_place_time_index` (`place_id`,`triggered_at`),
  ADD KEY `geofence_events_user_id_foreign` (`user_id`);

--
-- Indexes for table `locations`
--
ALTER TABLE `locations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `locations_user_id_unique` (`user_id`),
  ADD KEY `locations_coordinates_index` (`latitude`,`longitude`),
  ADD KEY `locations_recorded_at_index` (`recorded_at`);

--
-- Indexes for table `location_history`
--
ALTER TABLE `location_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `location_history_user_recorded_index` (`user_id`,`recorded_at`),
  ADD KEY `location_history_room_id_foreign` (`room_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `messages_room_created_index` (`room_id`,`created_at`),
  ADD KEY `messages_user_id_foreign` (`user_id`),
  ADD KEY `messages_reply_to_id_foreign` (`reply_to_id`);

--
-- Indexes for table `message_attachments`
--
ALTER TABLE `message_attachments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `message_attachments_message_id_foreign` (`message_id`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `places`
--
ALTER TABLE `places`
  ADD PRIMARY KEY (`id`),
  ADD KEY `places_room_active_index` (`room_id`,`is_active`),
  ADD KEY `places_created_by_foreign` (`created_by`);

--
-- Indexes for table `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `rooms_code_unique` (`code`),
  ADD KEY `rooms_created_by_index` (`created_by`);

--
-- Indexes for table `room_members`
--
ALTER TABLE `room_members`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `room_members_room_user_unique` (`room_id`,`user_id`),
  ADD KEY `room_members_user_id_foreign` (`user_id`),
  ADD KEY `room_members_role_index` (`room_id`,`role`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_username_unique` (`username`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD KEY `users_is_active_index` (`is_active`);

--
-- Indexes for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_profiles_user_id_foreign` (`user_id`),
  ADD KEY `user_profiles_sharing_status_index` (`sharing_status`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `alerts`
--
ALTER TABLE `alerts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `calls`
--
ALTER TABLE `calls`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `call_participants`
--
ALTER TABLE `call_participants`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `device_tokens`
--
ALTER TABLE `device_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `geofence_events`
--
ALTER TABLE `geofence_events`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `locations`
--
ALTER TABLE `locations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=77;

--
-- AUTO_INCREMENT for table `location_history`
--
ALTER TABLE `location_history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=74;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `message_attachments`
--
ALTER TABLE `message_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `places`
--
ALTER TABLE `places`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `room_members`
--
ALTER TABLE `room_members`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `user_profiles`
--
ALTER TABLE `user_profiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `alerts`
--
ALTER TABLE `alerts`
  ADD CONSTRAINT `alerts_acknowledged_by_foreign` FOREIGN KEY (`acknowledged_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `alerts_room_id_foreign` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `alerts_sender_id_foreign` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `alerts_target_user_id_foreign` FOREIGN KEY (`target_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `calls`
--
ALTER TABLE `calls`
  ADD CONSTRAINT `calls_initiator_id_foreign` FOREIGN KEY (`initiator_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `calls_room_id_foreign` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `call_participants`
--
ALTER TABLE `call_participants`
  ADD CONSTRAINT `call_participants_call_id_foreign` FOREIGN KEY (`call_id`) REFERENCES `calls` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `call_participants_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `device_tokens`
--
ALTER TABLE `device_tokens`
  ADD CONSTRAINT `device_tokens_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `geofence_events`
--
ALTER TABLE `geofence_events`
  ADD CONSTRAINT `geofence_events_place_id_foreign` FOREIGN KEY (`place_id`) REFERENCES `places` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `geofence_events_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `locations`
--
ALTER TABLE `locations`
  ADD CONSTRAINT `locations_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `location_history`
--
ALTER TABLE `location_history`
  ADD CONSTRAINT `location_history_room_id_foreign` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `location_history_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_reply_to_id_foreign` FOREIGN KEY (`reply_to_id`) REFERENCES `messages` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `messages_room_id_foreign` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `message_attachments`
--
ALTER TABLE `message_attachments`
  ADD CONSTRAINT `message_attachments_message_id_foreign` FOREIGN KEY (`message_id`) REFERENCES `messages` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `places`
--
ALTER TABLE `places`
  ADD CONSTRAINT `places_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `places_room_id_foreign` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `rooms`
--
ALTER TABLE `rooms`
  ADD CONSTRAINT `rooms_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `room_members`
--
ALTER TABLE `room_members`
  ADD CONSTRAINT `room_members_room_id_foreign` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `room_members_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD CONSTRAINT `user_profiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
