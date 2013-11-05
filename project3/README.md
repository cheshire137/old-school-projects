# Nile Project, 2007

The aim of this project is to implement a client-side database ecommerce
application. Let's assume that you have been hired by Nile Company (Amazon's
competitor) to keep track of their inventory. Nile sells two types of products:
games and toys.

There are three types of users:

1. customers
2. staff
3. managers

### Customers

In order to purchase from Nile, customers must first register. Once they are
registered, they query and purchase books or toys. These items are first placed
in a shopping basket, and then ordered. Customers can see the status of orders
(i.e., pending or shipped).

### Staff

Staff can check inventory, re-stock the online store with more components, view
all customer orders, and ship orders to customers. A staff member has an
online ID and a password that he/she can use to login into the company's
website to perform the previous listed tasks.

### Managers

Managers can do all tasks a staff member can do. In addition, managers can

1. view statistics about sale information (in the previous week, month, or year), and
2. decide sales promotions.

Managers needs to log into the company's website to perform these tasks.

## Customer Forms

- Register: Allows a new customer to register with NILE.
- Shopping: Allows a registered customer to list books or toys. The purchased items may be stored in a shopping basket.
- Purchase: Allows a registered customer to view their shopping basket and click "Purchase". This creates an order for the items that can then be viewed (and filled) by the NILE staff. NILE staff cannot see shopping baskets.
- Orders: Allows a registered customer to view the orders they have placed and see the status (either Pending or Shipped).

## Staff Forms

- Login: Screen Staff must log into in order to perform these functions.
- View Inventory: See a list of all items and their quantity.
- Update Inventory: Same as above, but with editable text boxes to change the quantity of any component.
- Ship Pending Orders: View the list of pending orders (components, price, customer info).

The staff member can click a "Ship It" button and, if all the components are
available, the status of the order changes from "Pending" to "Shipped" and the
quantities in the inventory are decreased. If the components are not available,
some error page listing the missing components is generated and the order
remains "Pending".

## Manager Forms

- Login Screen: may use the staff login form
- View Inventory, Update Inventory, Ship Pending Orders: the same as those of staff
- Sales Statistics View: the list of all items and sales history in the previous (week, month, or year)
- Sales Promotion View: the list of all items and decide the promotion rate.
