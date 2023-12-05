param (
    [int]$UserCount = 100000,
    [int]$BookCount = 50000,
    [int]$TransactionCount = 200000,
    [int]$ReviewCount = 300000
)

$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'

# Load the Bogus library
try {
    $scriptPath = $PSISE.CurrentFile.FullPath
    $scriptDirectory = [System.IO.Path]::GetDirectoryName($scriptPath)
    $bogusDllPath = Join-Path -Path $scriptDirectory -ChildPath "Bogus.dll"

    Add-Type -Path $bogusDllPath
} catch {
    Write-Host "Error loading Bogus library: $_"
    exit
}

# Database connection details
$connectionString = "Server=.;Database=BookHub;Integrated Security=True;"

# Create SqlConnection
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString

# Function to truncate tables
function Clear-Tables {
    $command = $connection.CreateCommand()

    # Delete data from child tables first
    $command.CommandText = "DELETE FROM [dbo].[Reviews]"
    $command.ExecuteNonQuery()
    $command.CommandText = "DELETE FROM [dbo].[Transactions]"
    $command.ExecuteNonQuery()

    # Then delete data from parent tables
    $command.CommandText = "DELETE FROM [dbo].[Books]"
    $command.ExecuteNonQuery()
    $command.CommandText = "DELETE FROM [dbo].[Users]"
    $command.ExecuteNonQuery()

    Write-Host "Tables cleared successfully."
}


# Function to generate and insert users
function Insert-Users {
    $faker = New-Object Bogus.Faker('en')
    $command = $connection.CreateCommand()
    $successfulUserInserts = 0

    for ($i = 0; $i -lt $UserCount; $i++) {
        $name = $faker.Name.FullName()
        # Include a unique identifier in the email address
        $email = "$($i)_$($faker.Internet.Email())"
        $password = $faker.Internet.Password(10)
        $joinDate = $faker.Date.Past(2)

        $command.CommandText = "INSERT INTO Users (Name, Email, Password, JoinDate) VALUES (@Name, @Email, @Password, @JoinDate)"
        $command.Parameters.Clear()
        $command.Parameters.Add("@Name", [System.Data.SqlDbType]::NVarChar).Value = $name
        $command.Parameters.Add("@Email", [System.Data.SqlDbType]::NVarChar).Value = $email
        $command.Parameters.Add("@Password", [System.Data.SqlDbType]::NVarChar).Value = $password
        $command.Parameters.Add("@JoinDate", [System.Data.SqlDbType]::DateTime).Value = $joinDate

        try {
            $null = $command.ExecuteNonQuery()
            $successfulUserInserts++
        } catch {
            Write-Host "Error inserting user: $_"
        }
    }

    Write-Output "$successfulUserInserts users inserted successfully."
}



# Function to generate and insert books
function Insert-Books {
    $faker = New-Object Bogus.Faker('en')
    $command = $connection.CreateCommand()
    $successfulInserts = 0

    for ($i = 0; $i -lt $BookCount; $i++) {
        $title = $faker.Lorem.Sentence($null, $null)
        $author = $faker.Name.FullName()
        $isbn = $faker.Random.Replace("###-###-####")
        $price = $faker.Random.Decimal(5, 100)
        $stockQuantity = $faker.Random.Int(0, 50)

        $command.CommandText = "INSERT INTO Books (Title, Author, ISBN, Price, StockQuantity) VALUES (@Title, @Author, @ISBN, @Price, @StockQuantity)"
        $command.Parameters.Clear()
        $command.Parameters.Add("@Title", [System.Data.SqlDbType]::NVarChar).Value = $title
        $command.Parameters.Add("@Author", [System.Data.SqlDbType]::NVarChar).Value = $author
        $command.Parameters.Add("@ISBN", [System.Data.SqlDbType]::NVarChar).Value = $isbn
        $command.Parameters.Add("@Price", [System.Data.SqlDbType]::Decimal).Value = $price
        $command.Parameters.Add("@StockQuantity", [System.Data.SqlDbType]::Int).Value = $stockQuantity

        $null = $command.ExecuteNonQuery()
        $successfulInserts++
    }

    Write-Output "$successfulInserts books inserted successfully."
}




# Function to generate and insert transactions
function Insert-Transactions {
    $faker = New-Object Bogus.Faker('en')
    $command = $connection.CreateCommand()
    $successfulTransactionInserts = 0

    for ($i = 0; $i -lt $TransactionCount; $i++) {
        $userID = $faker.Random.Int(1, $UserCount)
        $bookID = $faker.Random.Int(1, $BookCount)
        $transactionDate = $faker.Date.Recent(30)
        $amount = $faker.Random.Decimal(10, 500)

        $command.CommandText = "INSERT INTO Transactions (UserID, BookID, TransactionDate, Amount) VALUES (@UserID, @BookID, @TransactionDate, @Amount)"
        $command.Parameters.Clear()
        $command.Parameters.Add("@UserID", [System.Data.SqlDbType]::Int).Value = $userID
        $command.Parameters.Add("@BookID", [System.Data.SqlDbType]::Int).Value = $bookID
        $command.Parameters.Add("@TransactionDate", [System.Data.SqlDbType]::DateTime).Value = $transactionDate
        $command.Parameters.Add("@Amount", [System.Data.SqlDbType]::Decimal).Value = $amount

        $null = $command.ExecuteNonQuery()
        $successfulTransactionInserts++
    }

    Write-Output "$successfulTransactionInserts transactions inserted successfully."
}


# Function to generate and insert reviews
function Insert-Reviews {
    $faker = New-Object Bogus.Faker('en')
    $command = $connection.CreateCommand()
    $successfulReviewInserts = 0

    for ($i = 0; $i -lt $ReviewCount; $i++) {
        $bookID = $faker.Random.Int(1, $BookCount)
        $userID = $faker.Random.Int(1, $UserCount)
        $rating = $faker.Random.Int(1, 5)
        $comment = $faker.Lorem.Sentence($null, $null)
        $reviewDate = $faker.Date.Recent(60)

        $command.CommandText = "INSERT INTO Reviews (BookID, UserID, Rating, Comment, ReviewDate) VALUES (@BookID, @UserID, @Rating, @Comment, @ReviewDate)"
        $command.Parameters.Clear()
        $command.Parameters.Add("@BookID", [System.Data.SqlDbType]::Int).Value = $bookID
        $command.Parameters.Add("@UserID", [System.Data.SqlDbType]::Int).Value = $userID
        $command.Parameters.Add("@Rating", [System.Data.SqlDbType]::Int).Value = $rating
        $command.Parameters.Add("@Comment", [System.Data.SqlDbType]::NVarChar).Value = $comment
        $command.Parameters.Add("@ReviewDate", [System.Data.SqlDbType]::DateTime).Value = $reviewDate

        $null = $command.ExecuteNonQuery()
        $successfulReviewInserts++
    }

    Write-Output "$successfulReviewInserts reviews inserted successfully."
}


# Open connection and truncate tables
try {
    $connection.Open()
    Clear-Tables
} catch {
    Write-Host "Failed to open database connection or truncate tables: $_"
    exit
}

# Insert data
Insert-Users
Insert-Books
Insert-Transactions
Insert-Reviews

# Close connection
$connection.Close()
 
