-- LL-Core Database Installation
-- Run this SQL file to manually create tables (optional - tables are auto-created)

-- Players table
CREATE TABLE IF NOT EXISTS `ll_players` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) UNIQUE NOT NULL,
    `name` VARCHAR(100),
    `last_login` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player survival stats
CREATE TABLE IF NOT EXISTS `ll_player_survival` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` INT NOT NULL,
    `hunger` FLOAT DEFAULT 100,
    `thirst` FLOAT DEFAULT 100,
    `radiation` FLOAT DEFAULT 0,
    `sanity` FLOAT DEFAULT 100,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`player_id`) REFERENCES `ll_players`(`id`) ON DELETE CASCADE,
    INDEX `idx_player_id` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player missions
CREATE TABLE IF NOT EXISTS `ll_player_missions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` INT NOT NULL,
    `mission_id` VARCHAR(100) NOT NULL,
    `progress` TEXT,
    `completed` BOOLEAN DEFAULT FALSE,
    `completed_at` TIMESTAMP NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`player_id`) REFERENCES `ll_players`(`id`) ON DELETE CASCADE,
    INDEX `idx_player_mission` (`player_id`, `mission_id`),
    INDEX `idx_completed` (`completed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cutscenes
CREATE TABLE IF NOT EXISTS `ll_cutscenes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) UNIQUE NOT NULL,
    `data` LONGTEXT NOT NULL,
    `created_by` INT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`created_by`) REFERENCES `ll_players`(`id`) ON DELETE SET NULL,
    INDEX `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cutscene NPCs
CREATE TABLE IF NOT EXISTS `ll_cutscene_npcs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `cutscene_id` INT NOT NULL,
    `npc_data` TEXT NOT NULL,
    FOREIGN KEY (`cutscene_id`) REFERENCES `ll_cutscenes`(`id`) ON DELETE CASCADE,
    INDEX `idx_cutscene` (`cutscene_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;