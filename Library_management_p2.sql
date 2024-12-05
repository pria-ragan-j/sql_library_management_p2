-- Library_system_management_project_p2

-- Create tables

DROP TABLE IF EXISTS branch;
create table branch
(
branch_id varchar(10) primary key,
manager_id	varchar(10),
branch_address	varchar(50),
contact_no varchar(30)
);

DROP TABLE IF EXISTS employees;
create table employees(
emp_id	varchar(10) primary key,
emp_name varchar(30),
position varchar(30),
salary decimal(10,2),	
branch_id varchar(10),
foreign key (branch_id) references branch(branch_id)
);

DROP TABLE IF EXISTS members;
create table members (
member_id varchar(10) primary key,
member_name	varchar(30),
member_address varchar(50),
reg_date date
);

DROP TABLE IF EXISTS books;
create table books ( 
isbn varchar(50) primary key, 
book_title varchar(100),	
category	varchar(40),
rental_price decimal(10,2),	
status	varchar(10),
author	varchar(30),
publisher varchar(30)
);

DROP TABLE IF EXISTS issued_status;
create table issued_status(
issued_id	varchar(10) primary key,
issued_member_id	varchar(30),
issued_book_name	varchar(100),
issued_date	date,
issued_book_isbn varchar(50),	
issued_emp_id varchar(10),
foreign key (issued_member_id) references members(member_id),
foreign key (issued_book_isbn) references books(isbn),
foreign key (issued_emp_id) references employees(emp_id)
);

DROP TABLE IF EXISTS return_status;
create table return_status(
return_id VARCHAR(10) PRIMARY KEY,
issued_id VARCHAR(30),
return_book_name VARCHAR(80),
return_date DATE,
return_book_isbn VARCHAR(50),
FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);


-- Task 1. Create a New Book Record 
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"


insert into books 
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

select * from books;


--Task 2: Update an Existing Member's Address.

update members 
set member_address = '125 Oak st'
where member_id = 'C103';

--Task 3 Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

delete from issued_status
where issued_id = 'IS121';

--Task 4 Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

select * from issued_status
where issued_emp_id = 'E101';


--Task 5  List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.

select issued_emp_id , count(*) as Number_of_books_issued from issued_status
group by issued_emp_id
having count(*) > 1;


--Create view As Select
--Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results 
-- each book and total book_issued_cnt**

create view book_issued_count as

(select b.isbn,b.book_title,count(*) as issued_count from books b
join issued_status ist
on b.isbn = ist.issued_book_isbn
group by  b.isbn,b.book_title
order by  count(*) desc);

select book_issued_count;

--Data Analysis & Findings
--The following SQL queries were used to address specific questions:

--Task 7. Retrieve All Books in a Specific Category:Classic

select * from books
where category = 'Classic';

--Task 8: Find Total Rental Income by Category.


select b.category,sum(b.rental_price) as Total_income
from books b join issued_status ist 
on b.isbn = ist.issued_book_isbn
group by b.category
order by sum(b.rental_price) desc;

--Task 9 List Members Who Registered in the Last 365 Days:

SELECT *,(CURRENT_DATE-reg_date) as date_diff FROM members
where (CURRENT_DATE-reg_date) <= '365';


-- Task 10. List Employees with Their Branch Manager's Name 
--and their branch details:

select e1.emp_id,e1.emp_name,e1.branch_id,e2.emp_name as manager
from employees e1 
join branch b
on e1.branch_id = b.branch_id
join employees e2
on e2.emp_id = b.manager_id;


-- Task 11.  Create a view of Books with Rental Price Above a Certain Threshold:

create view expensive_books as 
(select * from books 
where rental_price > 7) ;


select * from expensive_books;

-- Task 12.Retrieve the List of Books Not Yet Returned.

select ist.issued_book_name, ist.issued_date
from issued_status ist
left join return_status rst
using(issued_id)
where rst.return_id is null;

--Task 13: Identify Members with Overdue Books
--Write a query to identify members who have overdue books (assume a 30-day return period). 
--Display the member's_id, member's name, book title, issue date, and days overdue.

select m.member_id,m.member_name,ist.issued_book_name,ist.issued_date,
(current_date - ist.issued_date) as Days_overdue
from members m join issued_status ist
on m.member_id = ist.issued_member_id
left join return_status rst 
using(issued_id)
where rst.return_id is null
order by m.member_id;


--Task 15. Branch performance report create a query that generates a perfromance 
--report for each branch, showing number of books issued, number of book returned
--and the total revenue generated from book rentals.


select e.branch_id,
count(ist.issued_id) as number_of_book_issued,
count(rst.issued_id) as number_of_book_return,
sum(b.rental_price)as total_revenue
from issued_status ist 
join employees e 
on  ist.issued_emp_id = e.emp_id
left join return_status rst
using(issued_id)
join books b
on ist.issued_book_isbn = B.isbn
group by e.branch_id
order by total_revenue desc;

--Task 16 Create view of active members containing members who have issued
-- atleast one book in the last 8 months.

Create view active_members as
(select m.member_name , (current_date -ist.issued_date)as day_diff
from members m join issued_status ist 
on m.member_id = ist.issued_member_id
where (current_date -ist.issued_date) < 240
order by issued_date);

select * from active_members;


--Task 17 Find employees with the most book issued. Write a query to find the 
--top 3 employees who have processed the most book issues. Display the employee
-- name , numbeof book processed and their branch.
select * from 
(select * , dense_rank()over(order by number_of_book_issued desc) as ranks from 
(select e.emp_name, e.branch_id, count(*) number_of_book_issued 
from employees e join issued_status ist
on e.emp_id = ist.issued_emp_id
group by e.emp_name, e.branch_id
order by number_of_book_issued desc) t1)t2
where ranks <= 3 ;

--Task 18 Identify book that issued more than once. Write a query to find 
-- the books issued for more than once.



select * from
(select issued_book_name,count(*) as number_of_item_book_isseued
from issued_status
group by issued_book_name
order by number_of_item_book_isseued desc)t1
where number_of_item_book_isseued >1;

--Task 20: Create view Objective: Create a view query to identify overdue books and calculate fines.

--Description: Write a CTAS query to create a new table that lists each member and the books 
--they have issued but not returned within 30 days. The table should include: The number of overdue books. 
--The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. 
--The resulting table should show: Member ID Number of overdue books Total fines.


select  issued_member_id,issued_book_name,issued_date,return_date,
(date - issued_date)-30 as overdue_days,
((date - issued_date)-30)*0.50 as overdue_amount
from 
(select ist.issued_member_id,ist.issued_book_name,ist.issued_date,rst.return_date,
case when rst.return_date is null then current_date 
when rst.return_date is not null then rst.return_date end as date
from issued_status ist left join return_status rst 
using(issued_id))t1;

