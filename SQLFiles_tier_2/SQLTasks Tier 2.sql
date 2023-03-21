/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT name
	FROM Facilities
    WHERE membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT(*) AS no_charge_count
    FROM Facilities
    WHERE membercost = 0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid, name, membercost, monthlymaintenance
	FROM Facilities
    WHERE membercost > 0
    AND membercost / monthlymaintenance < .2;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT *
    FROM Facilities
    WHERE facid in (1, 5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name, monthlymaintenance, (
    CASE WHEN monthlymaintenance > 100 THEN 'expensive' 
    ELSE 'cheap'
    END
) AS category
    FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT firstname, surname
    FROM Members
    WHERE joindate = (
        SELECT MAX(joindate)
        FROM Members
    );

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
-- this is ambiguous about whether the duplication in question is by member-court pairs or by member
-- i.e. if a member has used both court 1 and court 2, should these be listed separately?
-- the query below lists them separately because together would be a headache

SELECT DISTINCT Facilities.name AS court_name, CONCAT(surname, ', ', firstname) as member_name
    FROM Members
    INNER JOIN Bookings
    USING (memid) 
    INNER JOIN Facilities
    USING (facid)
    WHERE Facilities.name LIKE 'Tennis%'
    AND memid <> 0
    ORDER BY member_name;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
SELECT Facilities.name as facility, 
    CONCAT(surname, ', ', firstname) as member_name, 
    (CASE WHEN memid = 0 THEN slots * guestcost
        ELSE slots * membercost
    END) AS cost
    FROM Facilities
    INNER JOIN Bookings USING (facid)
    INNER JOIN Members USING (memid)
    WHERE starttime LIKE '2012-09-14%'
    AND (CASE WHEN memid = 0 THEN slots * guestcost
        ELSE slots * membercost
    END) > 30
    ORDER BY cost DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT facility_name, member_name, cost
    FROM (
        SELECT name as facility_name,
            CONCAT(surname, ', ', firstname) as member_name,
            (CASE WHEN memid = 0 THEN slots * guestcost
                ELSE slots * membercost
            END) AS cost
            FROM Facilities
            INNER JOIN Bookings USING (facid)
            INNER JOIN Members USING (memid)
            WHERE starttime LIKE '2012-09-14%'
    ) AS subquery
    WHERE cost > 30
    ORDER BY cost DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS: */
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT name, SUM(revenue) as total_revenue
    FROM (
        SELECT name,
        (
            CASE WHEN memid = 0 THEN slots * guestcost
            ELSE slots * membercost
            END
        ) AS revenue
        FROM Members 
        INNER JOIN Bookings USING (memid)
        INNER JOIN Facilities USING (facid)
    )
    GROUP BY name 
    HAVING SUM(revenue) < 1000 
    ORDER BY total_revenue;

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

-- SQLite syntax `||` for string concatenation
SELECT m.surname, m.firstname, r.firstname || ' ' || r.surname as recommender
    FROM Members as m
    LEFT JOIN Members as r
    ON m.recommendedby = r.memid
    WHERE m.memid <> 0 -- excluding the guest entry
    ORDER BY m.surname, m.firstname;

/* Q12: Find the facilities with their usage by member, but not guests */

-- interpreting this as total number of slots booked by members

SELECT name, SUM(slots) as total_slots_booked
    FROM Facilities
    INNER JOIN Bookings USING (facid)
    WHERE memid <> 0
    GROUP BY facid
    ORDER BY name;

/* Q13: Find the facilities usage by month, but not guests */
SELECT name, month, SUM(slots) AS total_slots_booked
    FROM Facilities
    INNER JOIN (
        SELECT facid, memid, slots, (
            CASE WHEN starttime LIKE '2012-07%' THEN 7
            WHEN starttime LIKE '2012-08%' THEN 8
            ELSE 9
            END
        ) AS month
        FROM Bookings
    ) AS bookings_months USING (facid)
    WHERE memid <> 0
    GROUP BY facid, month
    ORDER BY name, month;
