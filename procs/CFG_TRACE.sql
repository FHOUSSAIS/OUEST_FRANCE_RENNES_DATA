SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_TRACE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_mon_id : Identifiant moniteur
--			  @v_log_id : Identifiant log
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des moniteurs et logs
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_TRACE]
	@v_action smallint,
	@v_ssaction	smallint,
	@v_mon_id varchar(128),
	@v_log_id varchar(128),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint

	BEGIN TRAN
	SELECT @v_retour = 113
	SET @v_error = 0
	IF @v_action = 2
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			DELETE ASSOCIATION_LOG_MONITEUR WHERE ALM_MONITEUR = @v_mon_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE MONITEUR WHERE MON_ID = @v_mon_id
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			DELETE ASSOCIATION_LOG_MONITEUR WHERE ALM_LOG = @v_log_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE LOG WHERE LOG_ID = @v_log_id
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

