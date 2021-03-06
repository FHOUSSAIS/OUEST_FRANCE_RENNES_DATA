SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: IHM_SYNOPTIQUE
-- Paramètre d'entrée	: @v_syn_id : Identifiant de consultation
-- Paramètre de sortie	: 
-- Descriptif		: Utilisation du synoptique
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_SYNOPTIQUE]
	@v_syn_id bigint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_hostprocess varchar(8),
	@v_last_batch datetime

	IF @v_syn_id IS NULL
		EXEC SPV_SEQUENCE 1
	ELSE
	BEGIN
		SELECT TOP 1 @v_last_batch = last_batch, @v_hostprocess = hostprocess FROM master.dbo.sysprocesses (NOLOCK)
			WHERE program_name = APP_NAME() AND DB_NAME(dbid) = DB_NAME() ORDER BY login_time
		IF ((@v_hostprocess = HOST_ID()) OR (DATEDIFF(second, @v_last_batch, GETDATE()) >= 10))
		BEGIN
			IF @v_hostprocess <> HOST_ID()
				SELECT TOP 1 @v_hostprocess = hostprocess FROM master.dbo.sysprocesses (NOLOCK)
					WHERE program_name = APP_NAME() AND DB_NAME(dbid) = DB_NAME() AND hostprocess <> @v_hostprocess ORDER BY login_time
			IF @v_hostprocess = HOST_ID() or (
				SELECT TOP 1  DATEDIFF(second, last_batch, GETDATE()) FROM master.dbo.sysprocesses (NOLOCK)
					WHERE program_name = APP_NAME() AND DB_NAME(dbid) = DB_NAME() AND hostprocess = HOST_ID() ORDER BY login_time)>= 10
			BEGIN
				EXEC SPV_IMAGE
				EXEC SPV_TEXTE
			END
		END
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		SELECT SYN_ID, SYN_CATEGORIE, SYN_OBJET, SYN_TRACE FROM SYNOPTIQUE
			WHERE SYN_ID > @v_syn_id
			AND SYN_TYPE = 1 ORDER BY SYN_ID
	END

