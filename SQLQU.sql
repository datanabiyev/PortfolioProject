-- Cleaning Data in SQL queries
SELECT * 
FROM PortfolioProject..NashvilleHousing


-------------------------------------------------------------------------------------------------------------------------------------------------
-- Standartize the Date format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data
SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Breaking out Adress into Individual columns

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as Address
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) 

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))



-- Easier way
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'), 3)
, PARSENAME(REPLACE(OwnerAddress,',','.'), 2)
, PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3) 

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1) 

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in SoldAsVacant column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'N' THEN 'No'
	   WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'No'
	   WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   ELSE SoldAsVacant
	   END

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates FEE
/*
1) ROW_NUMBER() OVER (...): is a window function that assigns a unique sequential 
integer to rows within the specified partition. The ROW_NUMBER() function is used 
to enumerate the rows.

PARTITION BY divides the result set into partitions to which the ROW_NUMBER() function
is applied. Each partition is defined by the unique combination of the columns listed:
ParcelID
PropertyAddress
SalePrice
SaleDate
LegalReference
Rows with the same values in these columns are placed in the same partition.

ORDER BY UniqueID specifies the order in which the rows in each partition are 
numbered. The numbering restarts at 1 for each partition, ordered by UniqueID.

row_num is the alias given to the output of the ROW_NUMBER() function, effectively
creating a new column named row_num in the result set.


This orders the final result set by the ParcelID column.
*/
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID
) 
SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress
/*
Why this gives out the error:
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID
WHERE row_num > 1

while this works fine:
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID
) 
SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

In the first query, you attempted to filter rows using row_num directly in the main query. 
However, the sequence of SQL processing steps doesn't allow this because the WHERE clause is 
evaluated before the SELECT clause and the window functions are applied. This results in an error 
since row_num is not yet defined when the WHERE clause is evaluated.

The second query uses a Common Table Expression (CTE) to first create a temporary result set with 
the row_num column included. Then, it applies the WHERE clause to this result set. The CTE allows 
you to create a subquery with the ROW_NUMBER() function, which is then used in the outer query where 
the row_num column is available for filtering.

why this does not work?
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID
) 
SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

The issue in the provided query arises from the placement of the ORDER BY clause 
within the CTE. In SQL, the ORDER BY clause inside a CTE (or subquery) is not 
allowed unless it's used with TOP or FETCH NEXT to limit the number of rows. 
Here’s why and how to fix it:

Issue with the ORDER BY in the CTE
The ORDER BY ParcelID inside the CTE doesn't serve a meaningful purpose and causes
an error because it attempts to order the result set within the CTE. However, ORDER 
BY should be used in the outer query to order the final result set.

Corrected Query
To fix the issue, remove the ORDER BY clause from the CTE. You only need the ORDER
BY clause in the final SELECT statement to sort the final result set:
*/

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID
) 
DELETE 
FROM RowNumCTE
WHERE row_num > 1

-------------------------------------------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, Saledate

SELECT * 
FROM PortfolioProject..NashvilleHousing

-- 3rd video lecture Comment:
-- 9:05 Not sure if this has been pointed out, but the reason the SaleDate column didn't "update" 
-- here is because UPDATE does not change data types. The table is actually updating, but the data type for the column SaleDate is still datetime.
--To change data type, one has to use ``` ALTER TABLE NashvilleHousing ALTER COLUMN SaleDate DATE ```