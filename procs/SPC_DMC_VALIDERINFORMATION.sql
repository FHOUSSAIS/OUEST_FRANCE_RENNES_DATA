SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Valider l'information auprès de l'automate
--	@v_IdVariableAutomate : Variable automate à valider
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMC_VALIDERINFORMATION]
	@v_idVariableAutomate INT
AS
BEGIN
	DECLARE @CODE_OK INT = 0
	DECLARE	@CODE_KO INT = 1

	DECLARE @retour INT = @CODE_OK
	DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
	DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demaculeuse'
	DECLARE @trace VARCHAR(7500)
	DECLARE @local INT = 0

	DECLARE @var_activeMessage int

	-- Si la Variable Automate existe la table spécifique
	IF EXISTS (SELECT
				1
			FROM dbo.SPC_VARIABLE_AUTOMATE
			WHERE dbo.SPC_VARIABLE_AUTOMATE.SVA_IDVARIABLEAUTOMATE = @v_idVariableAutomate) 
		BEGIN

		SET @trace = 'SPC_DMC_VALIDERINFORMATION ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @v_idVariableAutomate), 'NULL')	
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace

		-- Vérification Groupe de Variable
		-- Si existe une autre variable appartenant au même groupe (même Active Message)
		-- Et que son Etat est à 0 (Non écris)
		IF EXISTS (	SELECT
						1
					FROM dbo.SPC_VARIABLE_AUTOMATE AS A_VALIDER
					JOIN dbo.SPC_VARIABLE_AUTOMATE AS AUTRE_VARIABLE_GROUPE
						ON A_VALIDER.SVA_ACTIVEMESSAGE = AUTRE_VARIABLE_GROUPE.SVA_ACTIVEMESSAGE
						AND ISNULL(AUTRE_VARIABLE_GROUPE.SVA_ETAT, 0) = 0
						AND AUTRE_VARIABLE_GROUPE.SVA_IDVARIABLEAUTOMATE <> @v_idVariableAutomate
					WHERE A_VALIDER.SVA_IDVARIABLEAUTOMATE = @v_idVariableAutomate) 
		BEGIN
			SET @trace = 'SPC_DMC_VALIDERINFORMATION ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @v_idVariableAutomate), 'NULL')	
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'DEBUG',
										@v_trace = @trace
			-- Mise à jour de l'information spécifique
			UPDATE dbo.SPC_VARIABLE_AUTOMATE
			SET	SVA_ETAT = 1,
				SVA_DATE = GETDATE()
			WHERE dbo.SPC_VARIABLE_AUTOMATE.SVA_IDVARIABLEAUTOMATE = @v_idVariableAutomate
		END
		-- Dernière Variable du groupe => Il faut écrire la variable de l'active message
		ELSE
		BEGIN
			-- Récupération de l'identifiant de la variable automate de l'active message
			SELECT @var_activeMessage = dbo.SPC_VARIABLE_AUTOMATE.SVA_ACTIVEMESSAGE FROM dbo.SPC_VARIABLE_AUTOMATE WHERE dbo.SPC_VARIABLE_AUTOMATE.SVA_IDVARIABLEAUTOMATE = @v_idVariableAutomate

			-- Ecriture de la variable automate
			EXEC @retour = dbo.INT_SETVARIABLEAUTOMATE	@v_vau_idvariableautomate = @var_activeMessage,
														@v_vau_valeur = 1
			-- Si Erreur
			IF(@retour <> @CODE_OK)
			BEGIN
				SET @trace = 'INT_SETVARIABLEAUTOMATE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @var_activeMessage), 'NULL')	
						+ ', @v_vau_valeur = ' + ISNULL(CONVERT(VARCHAR, 1), 'NULL')	
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'ERREUR',
											@v_trace = @trace
			END
			-- Si écriture OK, on raz le groupe de l'active message
			ELSE
			BEGIN
				-- Mise à jour de l'information spécifique
				UPDATE dbo.SPC_VARIABLE_AUTOMATE
				SET	SVA_ETAT = 0,
					SVA_DATE = GETDATE()
				WHERE dbo.SPC_VARIABLE_AUTOMATE.SVA_ACTIVEMESSAGE = @var_activeMessage
			END
		END
	END

	


END

