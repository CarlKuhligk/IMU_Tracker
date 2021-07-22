-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Erstellungszeit: 22. Jul 2021 um 11:38
-- Server-Version: 10.4.18-MariaDB
-- PHP-Version: 8.0.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Datenbank: `imutracker`
--

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `measures`
--

CREATE TABLE `measures` (
  `id` int(11) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `accX` float NOT NULL,
  `accY` float NOT NULL,
  `accZ` float NOT NULL,
  `gyrX` float NOT NULL,
  `gyrY` float NOT NULL,
  `gyrZ` float NOT NULL,
  `temp` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Daten für Tabelle `measures`
--

INSERT INTO `measures` (`id`, `timestamp`, `accX`, `accY`, `accZ`, `gyrX`, `gyrY`, `gyrZ`, `temp`) VALUES
(134, '2021-07-19 12:41:07', 0.24, -0.18, -11, -0.04, 0.02, 0.01, 34.64),
(135, '2021-07-19 12:41:08', 0.25, -0.19, -10.99, -0.05, 0.01, 0.01, 34.66),
(136, '2021-07-19 12:41:09', 0.25, -0.19, -10.98, -0.04, 0.02, 0.01, 34.66),
(137, '2021-07-19 12:41:11', 0.27, -0.17, -10.97, -0.03, 0.02, -0.05, 34.64),
(138, '2021-07-19 12:41:12', 0.25, -0.17, -10.98, -0.04, 0.02, 0.01, 34.65),
(139, '2021-07-19 12:41:13', 0.25, -0.18, -10.95, -0.04, 0.02, 0.01, 34.63),
(140, '2021-07-19 12:41:14', 0.23, -0.16, -10.98, -0.04, 0.02, 0.01, 34.6),
(141, '2021-07-19 12:41:15', 0.23, -0.18, -10.97, -0.01, 0.03, 0.01, 34.63),
(142, '2021-07-19 12:41:17', 0.23, -0.21, -10.97, -0.04, 0.02, 0.01, 34.63),
(143, '2021-07-19 12:41:18', 0.22, -0.2, -11, -0.03, 0.02, 0.01, 34.6),
(144, '2021-07-19 12:41:19', 0.23, -0.21, -11, -0.04, 0.02, 0.01, 34.58),
(145, '2021-07-19 12:41:20', 0.23, -0.23, -10.99, -0.04, 0.02, 0.01, 34.57),
(146, '2021-07-19 12:41:21', 0.25, -0.23, -10.98, -0.04, 0.02, 0.01, 34.54),
(147, '2021-07-19 12:41:22', 0.22, -0.25, -10.96, -0.04, 0.02, 0.01, 34.54),
(148, '2021-07-19 12:41:23', 0.27, -0.22, -10.99, -0.04, 0.02, 0.01, 34.49),
(149, '2021-07-19 12:41:24', 0.26, -0.18, -10.96, -0.04, 0.02, 0.01, 34.49),
(150, '2021-07-19 12:41:25', 0.26, -0.19, -10.98, -0.04, 0.02, 0.01, 34.45),
(151, '2021-07-19 12:41:27', 0.24, -0.22, -10.99, -0.04, 0.02, 0.01, 34.43),
(152, '2021-07-19 12:41:28', 0.25, -0.25, -10.97, -0.05, 0.02, 0.01, 34.39),
(153, '2021-07-19 12:41:29', 0.25, -0.2, -10.96, -0.04, 0.02, 0.01, 34.36),
(154, '2021-07-19 12:41:30', 0.23, -0.18, -10.98, -0.04, 0.02, 0.01, 34.33),
(155, '2021-07-19 12:41:31', 0.23, 0.29, -11.19, 0.32, 0.08, -0.01, 34.31);

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `measures`
--
ALTER TABLE `measures`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `measures`
--
ALTER TABLE `measures`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=156;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
