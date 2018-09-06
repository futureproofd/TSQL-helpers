--Temp Wildcard table
DECLARE @i int
DECLARE @id int
DECLARE @wildcard TABLE (
    NUM smallint IDENTITY(1,1),
    SYMBOL varchar(1)
)

--Temp output table for invalid emails
DECLARE @invalidEmails TABLE
(	
	ContactID varchar(128),
    Email varchar(256),
	ISVALID varchar(1)
)

-- load wildcard values
INSERT INTO @wildcard
	SELECT '!' UNION ALL
	SELECT '#' UNION ALL
	SELECT '$' UNION ALL
	SELECT '%' UNION ALL
	SELECT '^' UNION ALL
	SELECT '&' UNION ALL
	SELECT '*' UNION ALL
	SELECT '(' UNION ALL
	SELECT ')' UNION ALL
	SELECT '+' UNION ALL
	SELECT '=' UNION ALL
	SELECT '|' UNION ALL
	SELECT '\' UNION ALL
	SELECT '/' UNION ALL
	SELECT '?' UNION ALL
	SELECT '<' UNION ALL
	SELECT '>' UNION ALL
	SELECT '"' UNION ALL
	SELECT '''' UNION ALL
	SELECT '{' UNION ALL
	SELECT '}' UNION ALL
	SELECT ':' UNION ALL
	SELECT ',' UNION ALL
	SELECT ';' 
	;


DECLARE @numrows int 
DECLARE @symbol varchar(1)

SET @i = 1 --start counter
SET @numrows = (SELECT COUNT(*) FROM @wildcard)
IF @numrows > 0
    WHILE (@i <= (SELECT MAX(num) FROM @wildcard))
    BEGIN
        SET @symbol = (SELECT symbol FROM @wildcard WHERE num = @i) --loop through wildcards

		--Build results
		INSERT INTO @invalidEmails (ContactID, email, isvalid) 
			(
				SELECT ContactID,
					EMAIL,
					CASE               	
						WHEN charindex(@symbol, EMAIL) <> 0 THEN 0
						WHEN EMAIL NOT LIKE '[a-z,0-9,_,-]%@[a-z,0-9,_,-]%.[a-z][a-z]%' THEN 0
						WHEN LEN(EMAIL)-1 <= charindex('.', EMAIL) THEN 0
						ELSE 1
					END AS ISVALID
				FROM sysdba.CONTACT 
			)
        -- increment counter 
        SET @i = @i + 1
    END
 ;
 
 --Remove multiple hits for same contactID
 WITH CTE_InvalidEmails AS
 (
	SELECT *, 
		ROW_NUMBER()												
				OVER (PARTITION BY ContactID 
						ORDER BY ContactID
						) AS [RowCountC]
	FROM @invalidEmails
	WHERE isvalid = 0
)

--Results by Account Manager
SELECT UI.USERNAME, CTE.* 
FROM CTE_InvalidEmails CTE
	INNER JOIN sysdba.CONTACT C
		ON CTE.ContactID = C.CONTACTID
	INNER JOIN sysdba.ACCOUNT A
		ON A.ACCOUNTID = C.ACCOUNTID
	INNER JOIN sysdba.USERINFO UI
		ON UI.USERID = A.ACCOUNTMANAGERID
WHERE RowCountC < 2
ORDER BY USERNAME, CTE.Email