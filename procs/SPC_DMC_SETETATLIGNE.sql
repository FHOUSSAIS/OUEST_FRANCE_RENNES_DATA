SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- ================================================
-- Description:	Définition de l'état de la ligne
-- @v_idLigne	: Identifiant de ligne
-- @v_etatligne : Etat de la ligne (1:En Service Bobine/2:Hors Service Bobine /3:En Service Corbeille)
-- ================================================
CREATE PROCEDURE [dbo].[SPC_DMC_SETETATLIGNE]
	@v_idLigne int,
	@v_etatligne int
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demaculeuse'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @var_agvActiver INT
	
	SET @trace = 'SPC_DMC_SETETATLIGNE '
						+ ', @v_idLigne = ' + ISNULL(CONVERT(VARCHAR, @v_idLigne), 'NULL')	
						+ ', @v_etatligne = ' + ISNULL(CONVERT(VARCHAR, @v_etatligne), 'NULL')	
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace

	-- Vérification Ligne
	IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DEMACULEUSE WHERE dbo.SPC_DEMACULEUSE.SDL_IDLIGNE = @v_idLigne)
	BEGIN
		SET @trace = 'la ligne n existe pas ' + ISNULL(CONVERT(VARCHAR, @v_idLigne), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END
	-- Vérification Activité
	ELSE IF EXISTS(SELECT 1 FROM dbo.SPC_DEMACULEUSE WHERE dbo.SPC_DEMACULEUSE.SDL_IDLIGNE = @v_idLigne and dbo.SPC_DEMACULEUSE.SDL_ACTIF = 0)
	BEGIN
		SET @trace = 'la ligne n est pas active ' + ISNULL(CONVERT(VARCHAR, @v_idLigne), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END

	IF(@retour = @CODE_OK)
	BEGIN
		-- Récupération des informations
		SELECT @var_agvActiver = dbo.SPC_DEMACULEUSE.SDL_IDVARIABLE_AGV_ACTIVER FROM dbo.SPC_DEMACULEUSE WHERE dbo.SPC_DEMACULEUSE.SDL_IDLIGNE = @v_idLigne

		SET @trace = 'INT_SETVARIABLEAUTOMATE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @var_agvActiver), 'NULL')	
						+ ', @v_vau_valeur = ' + ISNULL(CONVERT(VARCHAR, @v_etatligne), 'NULL')	
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace

		EXEC @retour = dbo.INT_SETVARIABLEAUTOMATE @v_vau_idvariableautomate = @var_agvActiver, @v_vau_valeur = @v_etatligne
		IF (@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'INT_SETVARIABLEAUTOMATE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @var_agvActiver), 'NULL')	
						+ ', @v_vau_valeur = ' + ISNULL(CONVERT(VARCHAR, @v_etatligne), 'NULL')	
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
		END
	END

	RETURN @retour
END

