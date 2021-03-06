SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- ================================================
-- Description:	Créer une Bobine en station de déballage
-- @v_idLigne	: Identifiant de ligne
-- @v_laize	:
-- @v_diametre :
-- @v_grammage :
-- @v_idFournisseur :
-- @v_sensEnroulement :
-- ================================================
CREATE PROCEDURE [dbo].[SPC_DMC_CREERBOBINEDEBALLAGE]
	@v_idLigne INT,
	@v_laize	INT,
	@v_diametre INT,
	@v_grammage NUMERIC(5,2),
	@v_idFournisseur INT,
	@v_sensEnroulement INT
AS
BEGIN
DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demaculeuse'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @idBobine INT
DECLARE @idSysteme BIGINT
DECLARE @idBase BIGINT
DECLARE @idSousBase BIGINT
DECLARE @variableAutomate_idBobine1 INT
DECLARE @variableAutomate_idBobine2 INT
DECLARE @variableAutomate_newBobine INT
DECLARE @idBobineToChar1 VARCHAR(8) 
DECLARE @idBobineToChar2 VARCHAR(8)
DECLARE @val_newBobine int
	
	-- Vérification du poste de démacullage
	SET @val_newBobine = dbo.SPC_DMC_GETETATBOBINEDEBALLAGE(@v_idLigne)

	SET @trace = 'Poste Demaculage  '
		+ ', @val_newBobine = ' + ISNULL(CONVERT(VARCHAR, @val_newBobine), 'NULL')		
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace

	-- Bobine connue => KO
	IF(@val_newBobine  = 0)
	BEGIN
		RETURN -1 -- Message : Pas de nouvelle Bobine sur la station de démaculage
	END
	ELSE
	BEGIN
		-- Récupération de l'adresse du poste de démaculage
		SELECT
			@idSysteme = dbo.INT_ADRESSE.ADR_IDSYSTEME,
			@idBase = dbo.INT_ADRESSE.ADR_IDBASE,
			@idSousBase = dbo.INT_ADRESSE.ADR_IDSOUSBASE
		FROM dbo.INT_ADRESSE
		WHERE dbo.INT_ADRESSE.ADR_IDTYPEMAGASIN = 2
		AND dbo.INT_ADRESSE.ADR_MAGASIN = 3
		AND dbo.INT_ADRESSE.ADR_COTE = 2
		AND dbo.INT_ADRESSE.ADR_COULOIR = @v_idLigne

		SET @trace = 'Poste Demaculage  '
			+ ', @idSysteme = ' + ISNULL(CONVERT(VARCHAR, @idSysteme), 'NULL')		
			+ ', @idBase = ' + ISNULL(CONVERT(VARCHAR, @idBase), 'NULL')		
			+ ', @idSousBase = ' + ISNULL(CONVERT(VARCHAR, @idSousBase), 'NULL')		
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace

		-- Création de la bobine
		EXEC @retour = dbo.SPC_CHG_CREER_BOBINE	@v_idcharge = @idBobine OUT,
												@v_laize = @v_laize,
												@v_diametre = @v_diametre,
												@v_sensenroulement = @v_sensEnroulement,
												@v_grammage = @v_grammage,
												@v_fournisseur = @v_idFournisseur,
												@v_idsysteme = @idSysteme,
												@v_idbase = @idBase,
												@v_idsousbase = @idSousBase,
												@v_StatutBobine = 1
		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'SPC_CHG_CREER_BOBINE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
		END
		ELSE
		BEGIN
			SET @trace = 'Bobine crée sur Poste Demaculage  '
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'DEBUG',
										@v_trace = @trace
		END

		-- Envoi des Informations à l'automate
		IF(@retour = @CODE_OK)
		BEGIN
			/*Récupération des ID des mots automates*/
			SELECT
				@variableAutomate_newBobine = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_NEWBOBINE,
				@variableAutomate_idBobine1 = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1,
				@variableAutomate_idBobine2 = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2
			FROM SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
			WHERE SLV_IDLIGNE = @v_idLigne
			AND SLV_ACTION = 36

			SET @trace = 'Infod Action Automate  '
			+ ', @variableAutomate_newBobine = ' + ISNULL(CONVERT(VARCHAR, @variableAutomate_newBobine), 'NULL')		
			+ ', @variableAutomate_idBobine1 = ' + ISNULL(CONVERT(VARCHAR, @variableAutomate_idBobine1), 'NULL')		
			+ ', @variableAutomate_idBobine2 = ' + ISNULL(CONVERT(VARCHAR, @variableAutomate_idBobine2), 'NULL')		
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace

			-- Création de l'identifiant Bobine en 2 infos 
			EXEC @retour = SPC_DMC_GET_IDBOBINE	@v_idBobine = @idBobine,
												@v_idBobineToChar1 = @idBobineToChar1 OUTPUT,
												@v_idBobineToChar2 = @idBobineToChar2 OUTPUT
			IF(@retour = @CODE_OK)
			BEGIN
				-- Envoi Sens Enroulement
				IF(@v_sensenroulement IS NOT NULL)
				BEGIN
					EXEC @retour = INT_SETVARIABLEAUTOMATE	@v_vau_idvariableautomate = @variableAutomate_newBobine,
															@v_vau_valeur = 1
				END
				ELSE
				BEGIN
					SET @retour = @CODE_KO
				END
				IF(@retour <> @CODE_OK)
				BEGIN
					SET @trace = 'INT_SETVARIABLEAUTOMATE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
										+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @variableAutomate_newBobine), 'NULL')	
										+ ', @v_vau_valeur = ' + ISNULL(CONVERT(VARCHAR, 1), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'ERREUR',
												@v_trace = @trace
				END
				ELSE
				BEGIN
					SET @trace = 'Information Sens Enroulement Envoyée'
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace
				END
			END

			IF(@retour = @CODE_OK)
			BEGIN
				-- Envoi Id Bobine 1
				IF(@idBobineToChar1 IS NOT NULL)
				BEGIN
					EXEC @retour = INT_SETVARIABLEAUTOMATE	@v_vau_idvariableautomate = @variableAutomate_idBobine1,
															@v_vau_valeur = @idBobineToChar1
				END
				ELSE
				BEGIN
					SET @retour = @CODE_KO
				END
				IF(@retour <> @CODE_OK)
				BEGIN
					SET @trace = 'INT_SETVARIABLEAUTOMATE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
										+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @variableAutomate_idBobine1), 'NULL')	
										+ ', @v_vau_valeur = ' + ISNULL(CONVERT(VARCHAR, @idBobineToChar1), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'ERREUR',
												@v_trace = @trace
				END
				ELSE
				BEGIN
					SET @trace = 'Information Bobine 1 Envoyée'
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace
				END
			END

			IF(@retour = @CODE_OK)
			BEGIN									
				-- Envoi Id Bobine 2
				IF(@idBobineToChar1 IS NOT NULL)
				BEGIN
					EXEC @retour = INT_SETVARIABLEAUTOMATE	@v_vau_idvariableautomate = @variableAutomate_idBobine2,
															@v_vau_valeur = @idBobineToChar2
				END
				ELSE
				BEGIN
					SET @retour = @CODE_KO
				END										
				IF(@retour <> @CODE_OK)
				BEGIN
					SET @trace = 'INT_SETVARIABLEAUTOMATE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
										+ ', @v_vau_idvariableautomate = ' + ISNULL(CONVERT(VARCHAR, @variableAutomate_idBobine2), 'NULL')	
										+ ', @v_vau_valeur = ' + ISNULL(CONVERT(VARCHAR, @idBobineToChar2), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'ERREUR',
												@v_trace = @trace
				END
				ELSE
				BEGIN
					SET @trace = 'Information Bobine 2 Envoyée'
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace
				END
			END
		END
	END



	return @retour
END


