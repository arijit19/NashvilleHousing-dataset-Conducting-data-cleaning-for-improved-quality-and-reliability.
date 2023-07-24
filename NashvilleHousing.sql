/*
			Data Cleaning within SQL Queries
*/

SELECT * 
FROM Portfolio..NashvilleHousing;

-- Modifying the saledate Data Type
ALTER TABLE Portfolio..NashvilleHousing
ALTER COLUMN SaleDate DATE;

-- Verifying the presence of null values in PropertyAddress and addressing them
SELECT ParcelID, PropertyAddress
FROM Portfolio..NashvilleHousing
--WHERE PropertyAddress IS NULL
GROUP BY ParcelID, PropertyAddress
ORDER BY ParcelID;

-- Utilizing self join to explore the null values in PropertyAddress by leveraging the relationship between ParcelID, PropertyAddress, and UniqueID.
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM Portfolio..NashvilleHousing a
JOIN Portfolio..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Perform data population for the Property Address field
UPDATE a
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio..NashvilleHousing a
JOIN Portfolio..NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;


-- Separating Property Address into distinct columns: Address, City, and State.
-- Creating new columns
ALTER TABLE Portfolio..NashvilleHousing
ADD PropAddress NVARCHAR(255),
    PropCity NVARCHAR(255);

-- Update the new columns with split values
UPDATE nh
SET PropAddress = SUBSTRING(nh.PropertyAddress, 1, CHARINDEX(',', nh.PropertyAddress) - 1),
    PropCity = SUBSTRING(nh.PropertyAddress, CHARINDEX(',', nh.PropertyAddress) + 1, LEN(nh.PropertyAddress))
FROM Portfolio..NashvilleHousing nh;

SELECT
    PropertyAddress,
    PropAddress as Address,
    PropCity as City
FROM Portfolio..NashvilleHousing;


-- Separating Owner Address into distinct columns: Address, City, and State.
-- Creating new columns
ALTER TABLE Portfolio..NashvilleHousing
ADD OwnrAddress NVARCHAR(255),
    OwnrCity NVARCHAR(255),
	OwnrState NVARCHAR(255);

-- Update the new columns with split values
UPDATE Portfolio..NashvilleHousing
SET OwnrAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnrCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnrState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

SELECT
    OwnerAddress,
    OwnrAddress as Address,
    OwnrCity as City,
	OwnrState as State
FROM Portfolio..NashvilleHousing;

--ALTER TABLE Portfolio..NashvilleHousing
--DROP COLUMN OwnrAddress,
--             OwnrCity;

--SELECT OwnerAddress 
--FROM Portfolio..NashvilleHousing

-- Retrieve distinct values of 'SoldAsVacant' and their respective counts
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS SoldAsVacantCount
FROM Portfolio..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacantCount;

-- Update the 'SoldAsVacant' column with 'Y' for 'Yes', 'N' for 'No', and keep other values unchanged
UPDATE Portfolio..NashvilleHousing
SET SoldAsVacant = CASE
                     WHEN SoldAsVacant = 'Yes' THEN 'Y'
                     WHEN SoldAsVacant = 'No' THEN 'N'
                     ELSE SoldAsVacant
                   END;


-- Common Table Expression (CTE) to identify duplicates using ROW_NUMBER()
WITH DuplicatesCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
    FROM Portfolio..NashvilleHousing
)

--SELECT UniqueID, row_num FROM DuplicatesCTE;
-- Delete duplicates from the NashvilleHousing table
-- Keeping only the row with the smallest UniqueID (original record)
-- All other duplicate rows will be removed
DELETE FROM DuplicatesCTE
WHERE row_num > 1;

-- Delete the unused columns from the NashvilleHousing table
ALTER TABLE Portfolio..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress;

-- Rename the column PropAddress to PropertyAddress
USE Portfolio;
GO
EXEC sp_rename 'NashvilleHousing.PropAddress', 'PropertyAddress';
GO

-- Rename the column PropCity to PropertyCity
USE Portfolio;
GO
EXEC sp_rename 'NashvilleHousing.PropCity', 'PropertyCity';
GO

-- Rename the column PropAddress to OwnerAddress
USE Portfolio;
GO
EXEC sp_rename 'NashvilleHousing.OwnrAddress', 'OwnerAddress';
GO

-- Rename the column OwnrCity to OwnerCity
USE Portfolio;
GO
EXEC sp_rename 'NashvilleHousing.OwnrCity', 'OwnerCity';
GO

-- Rename the column PropCity to OwnerState
USE Portfolio;
GO
EXEC sp_rename 'NashvilleHousing.OwnrState', 'OwnerState';
GO
