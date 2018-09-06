USE [YourDatabaseHere]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_EmailValidityCheck] (@strEmail VARCHAR(128))
RETURNS BIT
AS
/*
Function to check if the input is a valid email value or not.

Parameter:  @strEmail VARCHAR(128) - Email address to check for validity.


--Testers:
SELECT YourDatabaseHere.dbo.fn_EmailValidityCheck('12343@fakedom.com');

SELECT YourDatabaseHere.dbo.fn_EmailValidityCheck('marcus@@fakedom.com');

SELECT YourDatabaseHere.dbo.fn_EmailValidityCheck('marcus.fakedom.com');

SELECT YourDatabaseHere.dbo.fn_EmailValidityCheck('marcus.fakedom.c33om');

SELECT DISTINCT ContactID
			,Email
			,YourDatabaseHere.dbo.fn_EmailValidityCheck(Email) AS isValid
		FROM YourDatabaseHere.dbo.Contact C 
		WHERE YourDatabaseHere.dbo.fn_EmailValidityCheck(Email) = 1

-- Additional filtering conditions added
-- Additional allowed characters according to RFC 5322
	(for the exception T-SQL used characters)

*/

BEGIN  
DECLARE @bitValid BIT = 0;

DECLARE @tblAllowedChars TABLE (AllowedSomewhere CHAR(1) NOT NULL PRIMARY KEY
									,AllowedInDomain BIT NOT NULL DEFAULT 0
									)
	;
	
DECLARE @tblEmailChars TABLE (PositionId INTEGER NOT NULL PRIMARY KEY IDENTITY(1,1)
									,EmailChar CHAR(1)
									)
	;
	
	BEGIN  --Initialize tables
	IF (@strEmail IS NULL)
		BEGIN
		RETURN @bitValid
		END;

	INSERT INTO @tblAllowedChars
	(AllowedSomewhere
			)
	SELECT CHAR(N)
		FROM ACDFin.utl.Tally
		WHERE N BETWEEN ASCII('a') AND ASCII('z')
			OR N BETWEEN ASCII('0') AND ASCII('9')
			OR N = ASCII('@')
			OR N = ASCII('_')
			OR N = ASCII('.')
			OR N = ASCII('-')
			OR N = ASCII('+')
			OR N = ASCII('!')
			OR N = ASCII('+')
			OR N = ASCII('=')
			OR N = ASCII('#')
			OR N = ASCII('$')
			OR N = ASCII('%')
			OR N = ASCII('&')
			OR N = ASCII('*')
			--OR N = ASCII('/')
			OR N = ASCII('^')
			OR N = ASCII('`')
			OR N = ASCII('{')
			OR N = ASCII('}')
			OR N = ASCII('|')
			OR N = ASCII('~')
			--Not using single tick ' or forward slash / 
			;
			
	UPDATE AC
	SET AllowedInDomain = 1
		FROM @tblAllowedChars AC
		WHERE AC.AllowedSomewhere BETWEEN 'a' AND 'z'
			OR AC.AllowedSomewhere BETWEEN '0' AND '9'
			OR AC.AllowedSomewhere = '.'
			OR AC.AllowedSomewhere = '-'
		;


	SET @strEmail = LOWER(LTRIM(RTRIM(@strEmail)));

	INSERT INTO @tblEmailChars
	(EmailChar)
	SELECT SUBSTRING(@strEmail, T.N, 1)
		FROM ACDFin.utl.Tally T
		WHERE T.N <= LEN(@strEmail)
		;
	END;
	
	BEGIN --Filtering Conditions:
	--Local part: unallowed characters
	IF (NOT (EXISTS(SELECT E.EmailChar
						FROM @tblEmailChars E
							LEFT JOIN @tblAllowedChars A
								ON A.AllowedSomewhere = E.EmailChar
						WHERE A.AllowedSomewhere IS NULL
						)
				)
		--Only one @ symbol
		AND NOT (EXISTS(SELECT COUNT(*)
							FROM @tblEmailChars E
							WHERE E.EmailChar = '@'
							HAVING COUNT(*) <> 1
							)
					)
		--Domain check: after @ symbol containing unallowed characters
		AND NOT (EXISTS(SELECT E.EmailChar
							FROM @tblEmailChars E
								LEFT JOIN @tblAllowedChars A
									ON A.AllowedSomewhere = E.EmailChar
										AND A.AllowedInDomain = 1
							WHERE E.PositionId > CHARINDEX('@', @strEmail)
								AND A.AllowedSomewhere IS NULL
							)
					)
		--No repeating Character sequence
		AND NOT (SELECT CHARINDEX('..', @strEmail)) > 0
		AND NOT (SELECT CHARINDEX('--', @strEmail)) > 0
		AND NOT (SELECT CHARINDEX('++', @strEmail)) > 0
		--Local portion of address cannot exceed length of 64 according to RFC standards
		AND NOT (SELECT CHARINDEX('@', @strEmail)) > 65
			)
		BEGIN
		SET @bitValid = 1
		END;
	END;
	
RETURN @bitValid; 
END;
GO