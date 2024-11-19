--1--
/* What are the average property listing prices near schools with different ratings?
 * Description: By analyzing property prices near the school, 
 * the company can analyze whether high rated schools attract more customers, 
 * especially customers with childrens. 
 * This helps the company better position its go-to-market strategy and recommend more suitable properties to the customers.
 */

SELECT s.school_id, s.rating AS school_rating,
    COUNT(p.property_id) AS num_of_nearby_properties,
    AVG(l.listing_price) AS avg_listing_price
FROM 
    schools s
LEFT JOIN 
    school_property sp ON s.school_id = sp.school_id
LEFT JOIN 
    properties p ON sp.property_id = p.property_id
LEFT JOIN 
    listings l ON p.property_id = l.property_id
GROUP BY 
    s.school_id, s.rating;

--2--
/* What is the employee's education level in each office?
 * Description: From this, we can roughly see the distribution of employees' education levels by offices.  
 * Dream Homes NYC can adjust the hiring strategies by offices based on current employees' educational levels.
 * Then, the company can be more competitive in the real estate market.
 */

SELECT e.office_id, o.state, e.education, 
 		COUNT(e.employee_id) AS num_of_employees
FROM employees e
JOIN offices o ON e.office_id = o.office_id
GROUP BY e.office_id, o.state, e.education
ORDER BY e.office_id;

--3--
/* In the first half of 2024, what are the major income types and the corresponding total income amounts of each office?
 * Description: The company can get insights of the major income type by offices. 
 * Then, the company can compare the major income amounts of each office to adjust the management 
 * and allocation strategies to generate more revenues. 
 * Besides, the insights can provide a decision basis when dealing with low-income offices.
 */

WITH income_overview AS 
(	SELECT office_id, income_type,
    SUM(
        COALESCE(sale_income_amount, 0) + 
        COALESCE(rent_income_amount, 0) + 
        COALESCE(other_income_amount, 0)
       	) AS total_income_amount
    FROM total_income
    WHERE income_date BETWEEN '2024-01-01' AND '2024-06-30'
    GROUP BY office_id, income_type
),
	major_income AS 
(	SELECT 
        office_id,
        MAX(total_income_amount) AS max_income_amount
    FROM income_overview
    GROUP BY office_id
)
SELECT 
    i.office_id,
    i.income_type AS major_income_type,
    i.total_income_amount AS max_income_amount
FROM 
    income_overview i
JOIN 
    major_income m ON i.office_id = m.office_id AND i.total_income_amount = m.max_income_amount
ORDER BY i.office_id;

--4--
/* In the first half of 2024, which type(s) of expenses per office exceeded the allocated budget?
 * Description: Based on the results, the company can know the budget overruns by offices and 
 * optimize the resource allocation to improve the financial health. 
 * For offices with severe overruns, they may need to analyze the reasons targeting the specific expense type.
 */

SELECT office_id, expense_type, total_expenses, total_budgets,
	CASE WHEN total_expenses > total_budgets
		 THEN (total_expenses - total_budgets)
		 ELSE 0
	END
	AS exceeded_amount
FROM (SELECT 
        office_id,
        expense_type,
        SUM(actual_spending) AS total_expenses,
        SUM(budget_allocation) AS total_budgets
    FROM 
        office_expenses
    WHERE 
        expense_date BETWEEN '2024-01-01' AND '2024-06-30'
    GROUP BY 
        office_id, expense_type)
ORDER BY office_id, expense_type;

--5--
/* Which offices have less income than expense in total?
 * Description: This analytical procedure can help our client identify the financial health of each office 
 * and analyze the profits. 
 * After understanding each office's financial performance, 
 * the company can take actions in time to reduce risks and capture the potential opportunities.
 */

WITH total_income_per_office AS (
    SELECT office_id,
    SUM(
        COALESCE(sale_income_amount, 0) + 
        COALESCE(rent_income_amount, 0) + 
        COALESCE(other_income_amount, 0)
       	) AS total_income_amount
    FROM total_income
    WHERE income_date BETWEEN '2024-01-01' AND '2024-06-30'
    GROUP BY office_id
),
	 total_expense_per_office AS (
    SELECT
        office_id,
        SUM(actual_spending) AS total_expense_amount
    FROM office_expenses
    GROUP BY office_id
)
SELECT
    COALESCE(i.office_id, e.office_id) AS office_id,
    i.total_income_amount,
    e.total_expense_amount,
    COALESCE(i.total_income_amount, 0) - COALESCE(e.total_expense_amount, 0) AS profit
FROM total_income_per_office i
FULL OUTER JOIN total_expense_per_office e ON i.office_id = e.office_id
ORDER BY office_id;

--6--
/* What is the relationship between staff commissions and appointments?
 * Description: By understanding the relationship between the number of employees' appointments and the commissions received, 
 * it can help enterprises better allocate relevant resources to employees. 
 * For offices with large appointment volume but low commission income, 
 * the company can provide more reasonable resource allocation to improve employee loyalty and customer satisfaction.
 */

SELECT 
    e.office_id,
    o.address AS office_address,
    COUNT(a.appointment_id) AS total_appointments,
    SUM(COALESCE(rc.commission_amount, 0) + COALESCE(sc.commission_amount, 0)) AS total_commission
FROM employees e
LEFT JOIN offices o ON e.office_id = o.office_id
LEFT JOIN appointments a ON e.employee_id = a.employee_id
LEFT JOIN rental_commissions rc ON e.employee_id = (SELECT l.employee_id 
FROM rental_leases rl JOIN listings l ON rl.listing_id = l.listing_id 
WHERE rl.lease_id = rc.lease_id)
LEFT JOIN sale_commissions sc ON e.employee_id = (SELECT l.employee_id 
FROM sale_contracts sc2 JOIN listings l ON sc2.listing_id = l.listing_id 
WHERE sc2.contract_id = sc.contract_id)
GROUP BY e.office_id, o.address
ORDER BY e.office_id;

--7--
/* In the first half of 2024, when are the most successful contracts signed?
 * Description: By analyzing the number of successful contracts signed, it is possible to understand the impact of low and high seasons on a company's business. 
 * This helps to develop targeted marketing 
 * and business strategies to keep the business stable during the off-season and minimize the impact of seasonal fluctuations.
*/

SELECT 
    TO_CHAR(signing_date, 'YYYY-MM') AS month,
    COUNT(contract_id) AS successful_contracts
FROM 
    sale_contracts
GROUP BY 
    TO_CHAR(signing_date, 'YYYY-MM')
ORDER BY 
    successful_contracts DESC;

--8--
/* What is the composition of income in different regions?
 * Description: Analyzing the revenue of different regions can help enterprises find the revenue potential 
 * and market demand of these regions, so as to formulate more targeted marketing 
 * and sales strategies according to the market characteristics of different regions.
*/

SELECT 
    p.state AS region,
    SUM(CASE WHEN ti.income_type = 'sale' THEN ti.sale_income_amount ELSE 0 END) AS total_sale_income,
    SUM(CASE WHEN ti.income_type = 'rent' THEN ti.rent_income_amount ELSE 0 END) AS total_rent_income,
    SUM(CASE WHEN ti.income_type IN ('sale', 'rent', 'other') THEN 
            COALESCE(ti.sale_income_amount, 0) + COALESCE(ti.rent_income_amount, 0) + COALESCE(ti.other_income_amount, 0) 
        ELSE 0 
    END) AS total_income
FROM 
    total_income ti
LEFT JOIN 
    sale_contracts sc ON ti.contract_id = sc.contract_id
LEFT JOIN 
    rental_leases rl ON ti.lease_id = rl.lease_id
LEFT JOIN 
    listings l ON sc.listing_id = l.listing_id OR rl.listing_id = l.listing_id
LEFT JOIN 
    properties p ON l.property_id = p.property_id
WHERE 
    p.state IS NOT NULL
GROUP BY 
    p.state
ORDER BY 
    total_income DESC;

--9--
/* What are the implications of the difference in budget between renting and buying?
 * Description: By analyzing the budget distribution of rent purchase customers, enterprises can optimize resource allocation, 
 * formulate targeted marketing strategies, and provide customized customer service to meet the needs of different customer groups.
*/

SELECT 
    'buy' AS dealing_type,
    AVG(min_budget) AS avg_min_budget,
    AVG(max_budget) AS avg_max_budget
FROM client_preferences
WHERE dealing_type = 'buy'
UNION ALL
SELECT 
    'rent' AS dealing_type,
    AVG(min_budget) AS avg_min_budget,
    AVG(max_budget) AS avg_max_budget
FROM client_preferences
WHERE dealing_type = 'rent';

--10--
/* What will be the effect of the number of open houses in different states?
 * Description: By analyzing the number of open houses in different states, 
 * the company can learn more about the property supply market by state. 
 * Based on that, the company can adjust the resource allocation between different states and try to gain more market shares. 
*/

SELECT p.state,
       COUNT(oh.openhouse_id) AS total_num_open_houses
FROM open_houses oh
JOIN properties p ON oh.property_id = p.property_id
GROUP BY p.state;
