-- Drop legacy IsActive column from app.tUser.
-- Auth now treats presence in tUser as the source of truth.

IF COL_LENGTH('app.tUser', 'IsActive') IS NOT NULL
BEGIN
    DECLARE @df sysname;

    SELECT @df = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c
        ON c.default_object_id = dc.object_id
    WHERE dc.parent_object_id = OBJECT_ID('app.tUser')
      AND c.name = 'IsActive';

    IF @df IS NOT NULL
        EXEC('ALTER TABLE app.tUser DROP CONSTRAINT [' + @df + ']');

    ALTER TABLE app.tUser DROP COLUMN IsActive;
END;
