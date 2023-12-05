-- Create database
CREATE DATABASE BookHub
GO

USE BookHub
GO

-- Users Table
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100),
    Email NVARCHAR(100) UNIQUE,
    Password NVARCHAR(100),
    JoinDate DATETIME DEFAULT GETDATE()
);

-- Books Table
CREATE TABLE Books (
    BookID INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200),
    Author NVARCHAR(100),
    ISBN NVARCHAR(13) UNIQUE,
    Price DECIMAL(10, 2),
    StockQuantity INT
);

-- Transactions Table
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    BookID INT,
    TransactionDate DATETIME DEFAULT GETDATE(),
    Amount DECIMAL(10, 2),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);

-- Reviews Table
CREATE TABLE Reviews (
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    BookID INT,
    UserID INT,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(500),
    ReviewDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);


CREATE INDEX IDX_ISBN ON Books(ISBN);
CREATE INDEX IDX_TransactionDate ON Transactions(TransactionDate);
GO

-- View for User Transactions
CREATE VIEW V_UserTransactions AS
SELECT 
    u.UserID, 
    u.Name AS UserName, 
    SUM(t.Amount) AS TotalSpent
FROM 
    Users u
JOIN 
    Transactions t ON u.UserID = t.UserID
GROUP BY 
    u.UserID, u.Name;
GO
-- View for Book Reviews
CREATE VIEW V_BookReviews AS
SELECT 
    BookID, 
    AVG(Rating) AS AverageRating
FROM 
    Reviews
GROUP BY 
    BookID;
GO

-- Add New User
CREATE PROCEDURE sp_AddUser 
    @Name NVARCHAR(100), 
    @Email NVARCHAR(100), 
    @Password NVARCHAR(100)
AS
BEGIN
    INSERT INTO Users (Name, Email, Password)
    VALUES (@Name, @Email, @Password);
END;
GO

-- Add New Book
CREATE PROCEDURE sp_AddBook 
    @Title NVARCHAR(200), 
    @Author NVARCHAR(100), 
    @ISBN NVARCHAR(13), 
    @Price DECIMAL(10, 2), 
    @StockQuantity INT
AS
BEGIN
    INSERT INTO Books (Title, Author, ISBN, Price, StockQuantity)
    VALUES (@Title, @Author, @ISBN, @Price, @StockQuantity);
END;
GO

-- Process Transaction
CREATE PROCEDURE sp_ProcessTransaction 
    @UserID INT, 
    @BookID INT, 
    @Amount DECIMAL(10, 2)
AS
BEGIN
    INSERT INTO Transactions (UserID, BookID, Amount)
    VALUES (@UserID, @BookID, @Amount);
END;
GO

-- Add Review
CREATE PROCEDURE sp_AddReview 
    @BookID INT, 
    @UserID INT, 
    @Rating INT, 
    @Comment NVARCHAR(500)
AS
BEGIN
    INSERT INTO Reviews (BookID, UserID, Rating, Comment)
    VALUES (@BookID, @UserID, @Rating, @Comment);
END;
GO
