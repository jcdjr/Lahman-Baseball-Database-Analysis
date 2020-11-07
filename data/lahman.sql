--1.What range of years for baseball games played does the provided database cover?
-- A: 1871-2016
SELECT *
FROM teams

SELECT MIN(yearid) as min_year, MAX(yearid) as max_year
FROM teams

--2 Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
--Edward Carl Gaedel, "43
SELECT *
FROM people

SELECT namelast, namegiven, height
FROM people 
WHERE height IN (select MIN(height)
				   FROM people);
				   
SELECT height, playerid, namegiven, namelast
FROM people
ORDER BY height;

----How many games did he play in? 
SELECT DISTINCT teams.name, namelast, namefirst, height, appearances.g_all as games_played, appearances.yearid as year
FROM people
INNER JOIN appearances
ON people.playerid = appearances.playerid
INNER JOIN teams
ON appearances.teamid = teams.teamid
WHERE height IS NOT null
ORDER BY height, namelast
LIMIT 1;

-- 
WITH shortest_player AS (SELECT *
						FROM people
						ORDER BY height
						LIMIT 1),
sp_total_games AS (SELECT *
				  FROM shortest_player
				  LEFT JOIN appearances
				  USING(playerid))
SELECT DISTINCT(name), namelast, namefirst, height, g_all as games_played, sp_total_games.yearid
FROM sp_total_games
LEFT JOIN teams
USING(teamid);

-- 3. Find all players in the database who played at Vanderbilt University. 
--Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--Sort this list in descending order by the total salary earned. 
--Which Vanderbilt player earned the most money in the majors?
--A: David Taylor

SELECT *
FROM people
LIMIT 1;

SELECT *
FROM schools
LIMIT 1;

SELECT *
FROM collegeplaying
LIMIT 1;

SELECT *
FROM salaries
LIMIT 1;

WITH top_sal AS (SELECT DISTINCT(sal.yearid), p.namegiven AS first, p.namelast AS last, s.schoolname AS college, sal.salary
	FROM people AS p
	INNER JOIN salaries AS sal
	USING (playerid)
	INNER JOIN collegeplaying AS c
	USING(playerid)
	INNER JOIN schools AS s
	USING (schoolid)
	WHERE schoolname iLIKE '%vanderbilt%'
	ORDER BY salary DESC)
SELECT first, last, college, SUM(salary) total_sal
FROM top_sal
GROUP BY first,last,college
ORDER BY total_sal DESC;


SELECT p.namegiven AS first, p.namelast AS last, s.schoolname AS college, sal.salary
FROM people AS p
	INNER JOIN salaries AS sal
	USING (playerid)
	INNER JOIN collegeplaying AS c
	USING(playerid)
	INNER JOIN schools AS s
	USING (schoolid)
WHERE schoolname iLIKE '%vanderbilt%'
AND first = 'David Taylor'
GROUP BY first, last, s.schoolname, sal.salary
ORDER BY sal.salary DESC
LIMIT 12;

--4.Using the fielding table, group players into three groups based on their position: 
--label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
--Determine the number of putouts made by each of these three groups in 2016.

WITH pc AS (SELECT playerid, pos, po, yearid,
		CASE WHEN pos ILIKE '%of%' THEN 'Outfield'
		WHEN pos IN ('SS', '1B','2B','3B') THEN 'Infield'
		WHEN pos IN ('P','C') THEN 'Battery' END AS pos_cat
		FROM fielding)
SELECT pos_cat, SUM(po)
FROM pc
WHERE yearid = 2016
GROUP BY pos_cat

WITH fielding_group AS (SELECT playerid, pos, po AS putouts,
						CASE WHEN pos LIKE 'OF'
								THEN 'Outfield'
							WHEN pos LIKE 'SS'
							   OR pos LIKE '1B'
							   OR pos LIKE '2B'
							   OR pos LIKE '3B'
								THEN 'Infield'
							WHEN pos LIKE 'P'
							   OR pos LIKE 'C'
								THEN 'Battery' END AS field_position
					   FROM fielding
					   WHERE yearid = '2016'
					   GROUP BY playerid,pos,po)
SELECT field_position, COUNT(putouts) AS putouts
FROM fielding_group
GROUP BY field_position
ORDER BY putouts DESC;

--5.Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
--Do the same for home runs per game. Do you see any trends?

SELECT AVG(so), FLOOR(yearid/10)*10 AS decade
FROM batting
WHERE yearid >= 1920
GROUP BY yearid
ORDER BY yearid;

WITH avg_so_dec AS (SELECT AVG(so) AS avg_year,yearid, FLOOR(yearid/10)*10 AS decade
					FROM batting
					WHERE yearid >= 1920
					GROUP BY yearid
					ORDER BY yearid)
SELECT AVG(avg_year), decade
FROM avg_so_dec
GROUP BY decade;

WITH decades as (	
	SELECT 	generate_series(1920,2010,10) as low_b,
			generate_series(1929,2019,10) as high_b)
			
SELECT 	low_b as decade,
		--SUM(so) as strikeouts,
		--SUM(g)/2 as games,  -- used last 2 lines to check that each step adds correctly
		ROUND(SUM(so::numeric)/(sum(g::numeric)/2),2) as SO_per_game,  -- note divide by 2, since games are played by 2 teams
		ROUND(SUM(hr::numeric)/(sum(g::numeric)/2),2) as hr_per_game
FROM decades LEFT JOIN teams
	ON yearid BETWEEN low_b AND high_b
GROUP BY decade
ORDER BY decade

-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
--What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
--Then redo your query, excluding the problem year. 
--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
--What percentage of the time?	

--most # wins that did not win WS (SEA- 1998)
SELECT yearid, teamid, w AS max_wins, wswin, w+l AS total
FROM teams
WHERE yearid >= 1970
	AND yearid <= 2016
	AND wswin = 'N'
ORDER BY w DESC
LIMIT 1;

--least # wins that did win WS (LAN-1981)
SELECT yearid, teamid, w AS min_wins, wswin, w+l AS total
FROM teams
WHERE yearid >= 1970
	AND yearid <= 2016
	AND wswin = 'Y'
ORDER BY w
LIMIT 1;

--determine why this is the case. 
WITH total_wins AS (SELECT yearid, w, l, w+l AS total
		FROM teams
		WHERE yearid > 1970
		AND yearid < 2016)
SELECT ROUND(AVG(total))
FROM total_wins

----How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
--What percentage of the time?

--WINDOW

WITH rank_wins AS (SELECT yearid, teamid, w, RANK() OVER(PARTITION BY yearid ORDER BY w DESC) AS tm_rank, wswin
		FROM teams 
		WHERE yearid >= 1970
		AND yearid <= 2016
		AND yearid <> 1981)
SELECT * 
FROM rank_wins
WHERE  tm_rank = 1
	AND wswin IS NOT NULL;
	
SELECT teamid,
	w,
	yearid
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'N'
GROUP BY teamid, yearid, w
ORDER BY w DESC
LIMIT 1;
11:39
SELECT yearid,
	MAX(w)
FROM teams
WHERE yearid BETWEEN 1970 and 2016
AND wswin = 'Y'
GROUP BY yearid
INTERSECT
SELECT yearid,
	MAX(w)
FROM teams
WHERE yearid BETWEEN 1970 and 2016
GROUP BY yearid
ORDER BY yearid;

WITH ws_winners AS (SELECT yearid,
						MAX(w)
					FROM teams
					WHERE yearid BETWEEN 1970 and 2016
					AND wswin = 'Y'
					GROUP BY yearid
					INTERSECT
					SELECT yearid,
						MAX(w)
					FROM teams
					WHERE yearid BETWEEN 1970 and 2016
					GROUP BY yearid
					ORDER BY yearid)
SELECT (COUNT(ws.yearid)/COUNT(t.yearid)::float)*100 AS percentage
FROM teams as t LEFT JOIN ws_winners AS ws ON t.yearid = ws.yearid
WHERE t.wswin IS NOT NULL
AND t.yearid BETWEEN 1970 AND 2016;

--exploring
(SELECT yearid, MAX(w) AS max_wins
					FROM teams
 					WHERE yearid >= 1970
 					AND yearid <= 2016
					 AND yearid <> 1981
					GROUP BY yearid
					ORDER BY yearid)
------ 
(SELECT yearid, teamid, w, wswin
			FROM teams
			WHERE yearid >= 1970
 			AND yearid <= 2016
			AND yearid <> 1981
			ORDER BY yearid, w desc)
					
--6.Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. 
--(A stolen base attempt results either in a stolen base or being caught stealing.) 
--Consider only players who attempted at least 20 stolen bases.
WITH batting AS (SELECT playerid,
				SUM(sb) AS stolen_bases,
				SUM(cs) AS caught_stealing,
				SUM(sb) + SUM(cs) AS total_attempts,
				yearid AS year
				FROM batting
				GROUP BY playerid, yearid)
SELECT DISTINCT(CONCAT(namelast, ',', ' ', namefirst)) AS player_name,
	   SUM(total_attempts) AS total_attempts,
	   SUM(stolen_bases) AS stolen_success,
	   ROUND(SUM(stolen_bases::DECIMAL/total_attempts::DECIMAL)*100, 2) AS success_rate
FROM batting
JOIN people ON batting.playerid = people.playerid
WHERE total_attempts >= 20
	AND total_attempts IS NOT NULL
	AND stolen_bases IS NOT NULL
	AND year = '2016'
GROUP BY people.playerid
ORDER BY success_rate DESC


SELECT Concat(namefirst,' ',namelast), batting.yearid, ROUND(MAX(sb::decimal/(cs::decimal+sb::decimal))*100,2) as sb_success_percentage
FROM batting
INNER JOIN people on batting.playerid = people.playerid
WHERE yearid = '2016'
AND (sb+cs) >= 20
GROUP BY namefirst, namelast, batting.yearid
ORDER BY sb_success_percentage DESC;

-- 8.	Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). 
--Only consider parks where there were at least 10 games played. 
--Report the park name, team name, and average attendance. 
--Repeat for the lowest 5 average attendance.

SELECT *
FROM homegames 

SELECT park, team, attendance/games AS avg_attendance
FROM homegames
WHERE year = 2016
AND games >=10
ORDER BY avg_attendance DESC
LIMIT 5;

SELECT park, team, attendance/games AS avg_attendance
FROM homegames
WHERE year = 2016
AND games >=10
ORDER BY avg_attendance
LIMIT 5;

SELECT DISTINCT p.park_name, h.team,
	(h.attendance/h.games) as avg_attendance, t.name		
FROM homegames as h JOIN parks as p ON h.park = p.park
LEFT JOIN teams as t on h.team = t.teamid AND t.yearid = h.year
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5;

SELECT DISTINCT p.park_name, h.team,
	(h.attendance/h.games) as avg_attendance, t.name		
FROM homegames as h JOIN parks as p ON h.park = p.park
LEFT JOIN teams as t on h.team = t.teamid AND t.yearid = h.year
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance 
LIMIT 5;

--9.Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award.

SELECT namefirst, namelast, lgid
FROM awardsmanagers INNER JOIN people
USING (playerid)
WHERE 
LIMIT 1;

SELECT *
FROM awardsmanagers INNER JOIN people
USING (playerid)
LIMIT 1;

WITH manager_both AS (SELECT playerid, al.lgid AS al_lg, nl.lgid AS nl_lg,
					  al.yearid AS al_year, nl.yearid AS nl_year,
					  al.awardid AS al_award, nl.awardid AS nl_award
	FROM awardsmanagers AS al INNER JOIN awardsmanagers AS nl
	USING(playerid)
	WHERE al.awardid LIKE 'TSN%'
	AND nl.awardid LIKE 'TSN%'
	AND al.lgid LIKE 'AL'
	AND nl.lgid LIKE 'NL')

SELECT DISTINCT(people.playerid), namefirst, namelast, managers.teamid,
		managers.yearid AS year, managers.lgid
FROM manager_both AS mb LEFT JOIN people USING(playerid)
LEFT JOIN salaries USING(playerid)
LEFT JOIN managers USING(playerid)
WHERE managers.yearid = al_year OR managers.yearid = nl_year;

--BONUS 
WITH tn_colleges AS (SELECT schoolid,
					schoolname,
					schoolstate
					FROM schools
					WHERE schoolstate = 'TN'
					GROUP BY schoolid)
SELECT DISTINCT schoolname AS college,
	   AVG(salary)::TEXT::NUMERIC::MONEY AS avg_salary
FROM tn_colleges
JOIN collegeplaying ON tn_colleges.schoolid = collegeplaying.schoolid
JOIN people ON collegeplaying.playerid = people.playerid
JOIN salaries ON people.playerid = salaries.playerid
GROUP BY schoolname
ORDER BY avg_salary DESC; 


WITH mngr_list AS (SELECT playerid, awardid, COUNT(DISTINCT lgid) AS lg_count
				   FROM awardsmanagers
				   WHERE awardid = ‘TSN Manager of the Year’
				   		AND lgid IN (‘NL’, ‘AL’)
				   GROUP BY playerid, awardid
				   HAVING COUNT(DISTINCT lgid) = 2),
	mngr_full AS (SELECT playerid, awardid, lg_count, yearid, lgid
				   FROM mngr_list INNER JOIN awardsmanagers USING(playerid, awardid))
SELECT namegiven, namelast, name AS team_name
FROM mngr_full INNER JOIN people USING(playerid)
	INNER JOIN managers USING(playerid, yearid, lgid)
	INNER JOIN teams ON mngr_full.yearid = teams.yearid AND mngr_full.lgid = teams.lgid AND managers.teamid = teams.teamid
GROUP BY namegiven, namelast, name;
