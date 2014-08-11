
SET NOCOUNT ON
DECLARE @Table TABLE (idx BIGINT IDENTITY PRIMARY KEY, ColorName VARCHAR(128), ByteValue VARBINARY(64))

INSERT @Table (ColorName)
SELECT 'AliceBlue'UNION ALL
SELECT 'AntiqueWhite'UNION ALL
SELECT 'Aqua'UNION ALL
SELECT 'Aquamarine'UNION ALL
SELECT 'Azure'UNION ALL
SELECT 'Beige'UNION ALL
SELECT 'Bisque'UNION ALL
SELECT 'Black'UNION ALL
SELECT 'BlanchedAlmond'UNION ALL
SELECT 'Blue'UNION ALL
SELECT 'BlueViolet'UNION ALL
SELECT 'Brown'UNION ALL
SELECT 'BurlyWood'UNION ALL
SELECT 'CadetBlue'UNION ALL
SELECT 'Chartreuse'UNION ALL
SELECT 'Chocolate'UNION ALL
SELECT 'Coral'UNION ALL
SELECT 'CornflowerBlue'UNION ALL
SELECT 'Cornsilk'UNION ALL
SELECT 'Crimson'UNION ALL
SELECT 'Cyan'UNION ALL
SELECT 'DarkBlue'UNION ALL
SELECT 'DarkCyan'UNION ALL
SELECT 'DarkGoldenRod'UNION ALL
SELECT 'DarkGray'UNION ALL
SELECT 'DarkGreen'UNION ALL
SELECT 'DarkKhaki'UNION ALL
SELECT 'DarkMagenta'UNION ALL
SELECT 'DarkOliveGreen'UNION ALL
SELECT 'DarkOrange'UNION ALL
SELECT 'DarkOrchid'UNION ALL
SELECT 'DarkRed'UNION ALL
SELECT 'DarkSalmon'UNION ALL
SELECT 'DarkSeaGreen'UNION ALL
SELECT 'DarkSlateBlue'UNION ALL
SELECT 'DarkSlateGray'UNION ALL
SELECT 'DarkTurquoise'UNION ALL
SELECT 'DarkViolet'UNION ALL
SELECT 'DeepPink'UNION ALL
SELECT 'DeepSkyBlue'UNION ALL
SELECT 'DimGray'UNION ALL
SELECT 'DodgerBlue'UNION ALL
SELECT 'FireBrick'UNION ALL
SELECT 'FloralWhite'UNION ALL
SELECT 'ForestGreen'UNION ALL
SELECT 'Fuchsia' UNION ALL
SELECT 'Gainsboro' UNION ALL
SELECT 'GhostWhite' UNION ALL
SELECT 'Gold' UNION ALL
SELECT 'GoldenRod' UNION ALL
SELECT 'Gray' UNION ALL
SELECT 'Green' UNION ALL
SELECT 'GreenYellow' UNION ALL
SELECT 'HoneyDew' UNION ALL
SELECT 'HotPink' UNION ALL
SELECT 'IndianRed' UNION ALL
SELECT 'Indigo' UNION ALL
SELECT 'Ivory' UNION ALL
SELECT 'Khaki' UNION ALL
SELECT 'Lavender' UNION ALL
SELECT 'LavenderBlush' UNION ALL
SELECT 'LawnGreen' UNION ALL
SELECT 'LemonChiffon'

DECLARE @newTable TABLE (idx BIGINT, value VARBINARY(64))

DECLARE @previous BIGINT, @current BIGINT, @curpos BIGINT = 1, @MaxCount INT

SELECT @MaxCount = COUNT(1) FROM @Table;
WHILE(@curpos < @MaxCount + 1)
BEGIN TRY
       IF @curpos = 1 
              INSERT @newTable SELECT @curpos,1
       ELSE
       BEGIN
              SELECT
                     @current = value * CAST(2 AS BIGINT)
              FROM
                     @newTable
              WHERE
                     idx = @curpos - 1    

              INSERT @newTable SELECT @curpos, @current
       
       END

       IF @@ROWCOUNT = 0 BREAK;
       
       SET @curpos +=1;

END TRY
BEGIN CATCH
       SELECT ERROR_MESSAGE(),@curpos
       BREAK;
END CATCH


UPDATE t1
       SET t1.ByteValue = t2.value
FROM
       @Table t1
       INNER JOIN @newTable t2 ON t1.idx = t2.idx

SELECT *, CAST(ByteValue AS BIGINT) FROM @Table

GO

DECLARE @Table TABLE (Person VARCHAR(50), FavoriteColor BIGINT)

INSERT @Table 
SELECT
       'Eric',       16+512+33554432 --Azure,Blue,DarkGreen
UNION ALL
SELECT
       'Andy',2251799813685248 + 288230376151711744 +33554432 --Green,Khaki,DarkGreen



SELECT
       'Who likes Azure', *
FROM
       @Table 
WHERE
       FavoriteColor & 16 = 16

SELECT
       'Who likes DarkGreen', *
FROM
       @Table 
WHERE
       FavoriteColor & 33554432 = 33554432

SELECT
       'Who likes Khaki', *
FROM
       @Table 
WHERE
       FavoriteColor & CAST(288230376151711744 AS BIGINT) = CAST(288230376151711744 AS BIGINT)
