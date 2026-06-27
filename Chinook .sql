-- All tracks by unit price
SELECT TOP 10
    t.Name AS track_name,
    ar.Name AS artist,
    al.Title AS album,
    t.UnitPrice
FROM Track t
INNER JOIN Album al ON t.AlbumId = al.AlbumId
INNER JOIN Artist ar ON al.ArtistId = ar.ArtistId
ORDER BY ar.Name;

-- Customers from USA
SELECT
    FirstName + ' ' + LastName AS customer_name,
    City,
    State,
    Email
FROM Customer
WHERE Country = 'USA'
ORDER BY LastName;

-- Tracks per genre(only genres with more than 50 tracks)
SELECT
    g.Name AS genre,
    COUNT(t.TrackId) AS total_tracks
FROM Track t
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY g.Name
HAVING COUNT(t.TrackId) > 50
ORDER BY total_tracks DESC;

-- Total revenue per country
SELECT
    BillingCountry AS country,
    COUNT(InvoiceId) AS total_invoices,
    ROUND(SUM(Total), 2) AS total_revenue
FROM Invoice
GROUP BY BillingCountry
ORDER BY total_revenue DESC;

-- Average invoice value by country
SELECT
    BillingCountry AS country,
    ROUND(AVG(Total), 2) AS avg_invoice_value
FROM Invoice
GROUP BY BillingCountry
ORDER BY avg_invoice_value DESC;

-- Invoices from 2011
SELECT
    InvoiceId,
    CustomerId,
    InvoiceDate,
    Total
FROM Invoice
WHERE YEAR(InvoiceDate) = 2021
ORDER BY Total DESC;

-- Tracks, Album and Artist joined together
SELECT TOP 20
    ar.Name   AS artist,
    al.Title  AS album,
    t.Name    AS track,
    t.UnitPrice
FROM Track t
INNER JOIN Album al  ON t.AlbumId  = al.AlbumId
INNER JOIN Artist ar ON al.ArtistId = ar.ArtistId
ORDER BY ar.Name, al.Title, t.Name;

-- All customers and their invoices(LEFT JOIN)
SELECT
    c.FirstName + ' ' + c.LastName AS customer_name,
    c.Country,
    i.InvoiceId,
    i.Total
FROM Customer c
LEFT JOIN Invoice i ON c.CustomerId = i.CustomerId
ORDER BY customer_name;

-- Full purchase detail(customer, invoice, track, genre)
SELECT TOP 20
    c.FirstName + ' ' + c.LastName  AS customer_name,
    i.InvoiceDate,
    t.Name      AS track,
    g.Name      AS genre,
    il.UnitPrice,
    il.Quantity
FROM Customer c
INNER JOIN Invoice i      ON c.CustomerId  = i.CustomerId
INNER JOIN InvoiceLine il ON i.InvoiceId   = il.InvoiceId
INNER JOIN Track t        ON il.TrackId    = t.TrackId
INNER JOIN Genre g        ON t.GenreId     = g.GenreId
ORDER BY c.LastName, i.InvoiceDate;

-- Employees and their customers(Right join)
SELECT
    e.FirstName + ' ' + e.LastName  AS support_rep,
    e.Title,
    c.FirstName + ' ' + c.LastName  AS customer_name,
    c.Country
FROM Customer c
RIGHT JOIN Employee e ON c.SupportRepId = e.EmployeeId
ORDER BY support_rep;

-- Customers who spent more than average customer
SELECT
    c.FirstName + ' ' + c.LastName  AS customer_name,
    c.Country,
    ROUND(SUM(i.Total), 2)          AS total_spent
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
HAVING SUM(i.Total) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(Total) AS customer_total
        FROM Invoice
        GROUP BY CustomerId
    ) AS avg_sub
)
ORDER BY total_spent DESC;

-- Tracks that have never been purchased
SELECT
    t.Name   AS track_name,
    al.Title AS album
FROM Track t
JOIN Album al ON t.AlbumId = al.AlbumId
WHERE t.TrackId NOT IN (
    SELECT DISTINCT TrackId FROM InvoiceLine
)
ORDER BY al.Title, t.Name;

-- Top 5 genres by units sold
SELECT TOP 5
    genre,
    total_units_sold
FROM (
    SELECT
        g.Name          AS genre,
        SUM(il.Quantity) AS total_units_sold
    FROM InvoiceLine il
    JOIN Track t ON il.TrackId = t.TrackId
    JOIN Genre g ON t.GenreId  = g.GenreId
    GROUP BY g.Name
) AS genre_sales
ORDER BY total_units_sold DESC;

-- Rank customers by total spend within each country
SELECT
    country,
    customer_name,
    total_spent,
    ROW_NUMBER() OVER (
        PARTITION BY country
        ORDER BY total_spent DESC
    ) AS rank_in_country
FROM (
    SELECT
        c.Country  AS country,
        c.FirstName + ' ' + c.LastName  AS customer_name,
        ROUND(SUM(i.Total), 2) AS total_spent
    FROM Customer c
    JOIN Invoice i ON c.CustomerId = i.CustomerId
    GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
) AS ranked
ORDER BY country, rank_in_country;

-- Top  10 Artists by revenue
SELECT TOP 10 *
FROM (
    SELECT
        ar.Name                         AS artist,
        ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS total_revenue,
        RANK() OVER (
            ORDER BY SUM(il.UnitPrice * il.Quantity) DESC
        ) AS revenue_rank
    FROM InvoiceLine il
    JOIN Track t   ON il.TrackId  = t.TrackId
    JOIN Album al  ON t.AlbumId   = al.AlbumId
    JOIN Artist ar ON al.ArtistId = ar.ArtistId
    GROUP BY ar.ArtistId, ar.Name
) AS artist_revenue
ORDER BY revenue_rank;

-- Running total of each customer's spending over time
SELECT
    c.FirstName + ' ' + c.LastName  AS customer_name,
    i.InvoiceDate,
    i.Total,
    ROUND(SUM(i.Total) OVER (
        PARTITION BY c.CustomerId
        ORDER BY i.InvoiceDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS running_total
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
ORDER BY customer_name, i.InvoiceDate;

-- Monthly revenue trend with 3-month rolling average
SELECT
    invoice_year,
    invoice_month,
    monthly_revenue,
    ROUND(AVG(monthly_revenue) OVER (
        ORDER BY invoice_year, invoice_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3mo_avg
FROM (
    SELECT
        YEAR(InvoiceDate)  AS invoice_year,
        MONTH(InvoiceDate) AS invoice_month,
        ROUND(SUM(Total), 2) AS monthly_revenue
    FROM Invoice
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
) AS monthly
ORDER BY invoice_year, invoice_month;

-- Top 10 customers by lifetime value
SELECT TOP 10
    c.FirstName + ' ' + c.LastName  AS customer_name,
    c.Country,
    c.Email,
    COUNT(DISTINCT i.InvoiceId)     AS total_orders,
    ROUND(SUM(i.Total), 2)          AS lifetime_value
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country, c.Email
ORDER BY lifetime_value DESC;

-- Revenue trend by year
SELECT
    YEAR(InvoiceDate)       AS year,
    COUNT(InvoiceId)        AS total_invoices,
    ROUND(SUM(Total), 2)    AS annual_revenue
FROM Invoice
GROUP BY YEAR(InvoiceDate)
ORDER BY year;

-- Best selling tracks by units sold
SELECT TOP 15
    t.Name  AS track_name,
    ar.Name  AS artist,
    SUM(il.Quantity) AS total_units_sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS total_revenue
FROM InvoiceLine il
JOIN Track t   ON il.TrackId  = t.TrackId
JOIN Album al  ON t.AlbumId   = al.AlbumId
JOIN Artist ar ON al.ArtistId = ar.ArtistId
GROUP BY t.TrackId, t.Name, ar.Name
ORDER BY total_units_sold DESC;

-- Customer purchasing behavior
SELECT
    c.FirstName + ' ' + c.LastName  AS customer_name,
    c.Country,
    COUNT(i.InvoiceId) AS purchase_count,
    ROUND(AVG(i.Total), 2) AS avg_order_value,
    MIN(i.InvoiceDate) AS first_purchase,
    MAX(i.InvoiceDate) AS last_purchase
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
ORDER BY purchase_count DESC;

-- Which support rep drives the most revenue
SELECT
    e.FirstName + ' ' + e.LastName  AS support_rep,
    e.Title,
    COUNT(DISTINCT c.CustomerId)    AS customers_assigned,
    ROUND(SUM(i.Total), 2)          AS total_revenue_driven
FROM Employee e
JOIN Customer c ON c.SupportRepId = e.EmployeeId
JOIN Invoice i  ON i.CustomerId   = c.CustomerId
GROUP BY e.EmployeeId, e.FirstName, e.LastName, e.Title
ORDER BY total_revenue_driven DESC;