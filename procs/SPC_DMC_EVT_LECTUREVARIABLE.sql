SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Traitement de l'évènement de Lecture Variable
			@v_emetteurInterne = Emetteur Interne
			@v_emetteurExterne = Emetteur Externe
			@v_idVariableAutomate = Identifiant de la variable automate,
			@v_valeur = Valeur de la variable automate
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_DMC_EVT_LECTUREVARIABLE]
	@v_emetteurInterne INT,
	@v_emetteurExterne INT,
	@v_idVariableAutomate INT,
	@v_valeur VARCHAR(8000)
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demaculeuse'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @action INT
DECLARE @actionLibelle VARCHAR(8000)
DECLARE @ligneDemaculage INT
DECLARE @idBobine INT
DECLARE @idSysteme BIGINT
DECLARE @idBase BIGINT
DECLARE @idSousBase BIGINT
DECLARE @val_skateDisponible VARCHAR(8000)
DECLARE @val_positionSkate VARCHAR(8000)
DECLARE @val_sensEnroulement VARCHAR(8000)
DECLARE @val_idBobine1 VARCHAR(8000)
DECLARE @val_idBobine2 VARCHAR(8000)
DECLARE @val_newBobine VARCHAR(8000)
DECLARE @val_poidsBrut VARCHAR(8000)
DECLARE @val_poidsNet VARCHAR(8000)
DECLARE @val_type VARCHAR(8000)
DECLARE @val_destination INT


	IF(@v_emetteurInterne = -6)
	BEGIN
		-- Si Variable AGV (Type IO : Input Output)
		IF EXISTS (SELECT
			1
		FROM dbo.INT_VARIABLE_AUTOMATE
		WHERE dbo.INT_VARIABLE_AUTOMATE.VAU_IDVARIABLEAUTOMATE = @v_idVariableAutomate
		AND dbo.INT_VARIABLE_AUTOMATE.VAU_TYPE = 'IO')
		BEGIN
			EXEC @retour = dbo.SPC_DMC_VALIDERINFORMATION @v_idVariableAutomate = @v_idVariableAutomate
		END
	
		--  Si Type I Input
		IF EXISTS (SELECT
			1
		FROM dbo.INT_VARIABLE_AUTOMATE
		WHERE dbo.INT_VARIABLE_AUTOMATE.VAU_IDVARIABLEAUTOMATE = @v_idVariableAutomate
		AND dbo.INT_VARIABLE_AUTOMATE.VAU_TYPE = 'I')
		BEGIN
			-- Si Active Message
			IF EXISTS ( SELECT
							1
						FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
						WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE = @v_idVariableAutomate)
			BEGIN
				-- Récupération Action et Ligne
				SELECT
					@action = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTION,
					@actionLibelle = dbo.INT_GETLIBELLE(dbo.SPC_DMC_ACTION.SDA_IDTRADUCTION, 'fra'),
					@ligneDemaculage = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDLIGNE
				FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
				JOIN dbo.SPC_DMC_ACTION ON dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTION = dbo.SPC_DMC_ACTION.SDA_ACTION
				WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE = @v_idVariableAutomate

				-- Infos  Position Skate
				IF(@action = 12)
				BEGIN
					SELECT
						@val_skateDisponible = SKATE_DISPONIBLE.VAU_VALEUR,
						@val_positionSkate = POSITION_SKATE.VAU_VALEUR
					FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
					JOIN dbo.INT_VARIABLE_AUTOMATE SKATE_DISPONIBLE
						ON SKATE_DISPONIBLE.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_SKATEDISPONIBLE
					JOIN dbo.INT_VARIABLE_AUTOMATE POSITION_SKATE
						ON POSITION_SKATE.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_POSITIONSKATE
					WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE = @v_idVariableAutomate

					SET @trace = 'Action  ' + ISNULL(CONVERT(VARCHAR, @actionLibelle), 'NULL')	
						+ ', @ligneDemaculage = ' + ISNULL(CONVERT(VARCHAR, @ligneDemaculage), 'NULL')	
						+ ', @val_skateDisponible = ' + ISNULL(CONVERT(VARCHAR, @val_skateDisponible), 'NULL')	
						+ ', @val_positionSkate = ' + ISNULL(CONVERT(VARCHAR, @val_positionSkate), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace
				END
				-- Infos Bobine reçue
				ELSE IF(@action = 22)
				BEGIN
					SELECT
						@val_sensEnroulement = SENS_ENROULEMENT.VAU_VALEUR,
						@val_idBobine1 = BOBINE1.VAU_VALEUR,
						@val_idBobine2 = BOBINE2.VAU_VALEUR
					FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
					JOIN dbo.INT_VARIABLE_AUTOMATE SENS_ENROULEMENT
						ON SENS_ENROULEMENT.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_SENSENROULEMENT
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE1
						ON BOBINE1.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE2
						ON BOBINE2.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2
					WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE = @v_idVariableAutomate

					EXEC @retour = dbo.SPC_DMC_SET_IDBOBINE @v_idBobine = @idBobine OUT, @v_idBobineToChar1 = @val_idBobine1, @v_idBobineToChar2 = @val_idBobine2

					SET @trace = 'Action  ' + ISNULL(CONVERT(VARCHAR, @actionLibelle), 'NULL')	
						+ ', @ligneDemaculage = ' + ISNULL(CONVERT(VARCHAR, @ligneDemaculage), 'NULL')	
						+ ', @val_sensEnroulement = ' + ISNULL(CONVERT(VARCHAR, @val_sensEnroulement), 'NULL')	
						+ ', @idBobine = ' + ISNULL(CONVERT(VARCHAR, @idBobine), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace
				END

				-- Infos Bobine Station Déballage
				ELSE IF(@action = 31)
				BEGIN
					-- Récupération des informations liées à l'action
					SELECT
						@val_newBobine = NEW_BOBINE.VAU_VALEUR,
						@val_idBobine1 = BOBINE1.VAU_VALEUR,
						@val_idBobine2 = BOBINE2.VAU_VALEUR
					FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
					JOIN dbo.INT_VARIABLE_AUTOMATE NEW_BOBINE
						ON NEW_BOBINE.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_NEWBOBINE
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE1
						ON BOBINE1.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE2
						ON BOBINE2.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2
					WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE = @v_idVariableAutomate

					-- Si Bobine Connue
					if(@val_newBobine = 0)
					BEGIN
						-- Reconstitution de l'identifiant de la bobine
						EXEC @retour = dbo.SPC_DMC_SET_IDBOBINE @v_idBobine = @idBobine OUT, @v_idBobineToChar1 = @val_idBobine1, @v_idBobineToChar2 = @val_idBobine2

						SET @trace = 'Action  ' + ISNULL(CONVERT(VARCHAR, @actionLibelle), 'NULL')	
							+ ', @ligneDemaculage = ' + ISNULL(CONVERT(VARCHAR, @ligneDemaculage), 'NULL')	
							+ ', @val_newBobine = ' + ISNULL(CONVERT(VARCHAR, @val_newBobine), 'NULL')	
							+ ', @idBobine = ' + ISNULL(CONVERT(VARCHAR, @idBobine), 'NULL')	
						SET @trace = @procStock + '/' + @trace
						EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
													@v_log_idlog = 'DEBUG',
													@v_trace = @trace
					
						-- Récupération de l'adresse du poste de démaculage
						SELECT
							@idSysteme = dbo.INT_ADRESSE.ADR_IDSYSTEME,
							@idBase = dbo.INT_ADRESSE.ADR_IDBASE,
							@idSousBase = dbo.INT_ADRESSE.ADR_IDSOUSBASE
						FROM dbo.INT_ADRESSE
						WHERE dbo.INT_ADRESSE.ADR_IDTYPEMAGASIN = 2
						AND dbo.INT_ADRESSE.ADR_MAGASIN = 3
						AND dbo.INT_ADRESSE.ADR_COTE = 2
						AND dbo.INT_ADRESSE.ADR_COULOIR = @ligneDemaculage
					

						SET @trace = 'Poste Demaculage  '
							+ ', @idSysteme = ' + ISNULL(CONVERT(VARCHAR, @idSysteme), 'NULL')	
							+ ', @idBase = ' + ISNULL(CONVERT(VARCHAR, @idBase), 'NULL')	
							+ ', @idSousBase = ' + ISNULL(CONVERT(VARCHAR, @idSousBase), 'NULL')	
						SET @trace = @procStock + '/' + @trace
						EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
													@v_log_idlog = 'DEBUG',
													@v_trace = @trace

						-- Transfert de la charge sur l'adresse du poste de démaculage
						EXEC @retour = dbo.INT_TRANSFERCHARGE	@v_chg_idcharge = @idBobine,
																@v_adr_idsysteme_depose = @idSysteme,
																@v_adr_idbase_depose = @idBase,
																@v_adr_idsousbase_depose = @idSousBase,
																@v_chg_orientation_depose = 0,
																@v_forcage = 1 -- On force pour éviter la désynchro
						IF(@retour <> @CODE_OK)
						BEGIN
							SET @trace = 'INT_TRANSFERCHARGE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
							SET @trace = @procStock + '/' + @trace
							EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
														@v_log_idlog = 'ERREUR',
														@v_trace = @trace
						END
						ELSE
						BEGIN
							SET @trace = 'Bobine sur Poste Demaculage  '
							SET @trace = @procStock + '/' + @trace
							EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
														@v_log_idlog = 'DEBUG',
														@v_trace = @trace
						END
					END
					-- Sinon Bobine Inconnue => On ne fait, initiative opérateur
					ELSE
					BEGIN
						SET @trace = 'Bobine Inconnue sur Poste Demaculage  '
							SET @trace = @procStock + '/' + @trace
							EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
														@v_log_idlog = 'DEBUG',
														@v_trace = @trace
					END
				END
				-- Infos Poids Brut
				ELSE IF(@action = 32)
				BEGIN
					-- Récupération des informations liées à l'action
					SELECT
						@val_poidsBrut = POIDS_BRUT.VAU_VALEUR,
						@val_idBobine1 = BOBINE1.VAU_VALEUR,
						@val_idBobine2 = BOBINE2.VAU_VALEUR
					FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
					JOIN dbo.INT_VARIABLE_AUTOMATE POIDS_BRUT
						ON POIDS_BRUT.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_POIDSBRUT
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE1
						ON BOBINE1.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE2
						ON BOBINE2.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2
					WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE = @v_idVariableAutomate

					-- Reconstitution de l'identifiant de la bobine
					EXEC @retour = dbo.SPC_DMC_SET_IDBOBINE @v_idBobine = @idBobine OUT, @v_idBobineToChar1 = @val_idBobine1, @v_idBobineToChar2 = @val_idBobine2

					SET @trace = 'Action  ' + ISNULL(CONVERT(VARCHAR, @actionLibelle), 'NULL')	
						+ ', @ligneDemaculage = ' + ISNULL(CONVERT(VARCHAR, @ligneDemaculage), 'NULL')	
						+ ', @val_poidsBrut = ' + ISNULL(CONVERT(VARCHAR, @val_poidsBrut), 'NULL')	
						+ ', @idBobine = ' + ISNULL(CONVERT(VARCHAR, @idBobine), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace

					-- Modification du poids
					EXEC @retour = dbo.SPC_CHG_MODIFIER_POIDS_BRUT @v_idBobine = @idBobine, @v_poidsBrut = @val_poidsBrut
					IF(@retour <> @CODE_OK)
					BEGIN
						SET @trace = 'SPC_CHG_MODIFIER_POIDS_BRUT ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						SET @trace = @procStock + '/' + @trace
						EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
													@v_log_idlog = 'ERREUR',
													@v_trace = @trace
					END
				END
				ELSE IF(@action = 33)		
				BEGIN
					-- Récupération des informations liées à l'action
					SELECT
						@val_poidsNet = POIDS_NET.VAU_VALEUR,
						@val_idBobine1 = BOBINE1.VAU_VALEUR,
						@val_idBobine2 = BOBINE2.VAU_VALEUR
					FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
					JOIN dbo.INT_VARIABLE_AUTOMATE POIDS_NET
						ON POIDS_NET.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_POIDSNET
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE1
						ON BOBINE1.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE2
						ON BOBINE2.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2
					WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE = @v_idVariableAutomate

					-- Reconstitution de l'identifiant de la bobine
					EXEC @retour = dbo.SPC_DMC_SET_IDBOBINE @v_idBobine = @idBobine OUT, @v_idBobineToChar1 = @val_idBobine1, @v_idBobineToChar2 = @val_idBobine2

					SET @trace = 'Action  ' + ISNULL(CONVERT(VARCHAR, @actionLibelle), 'NULL')	
						+ ', @ligneDemaculage = ' + ISNULL(CONVERT(VARCHAR, @ligneDemaculage), 'NULL')	
						+ ', @val_poidsNet = ' + ISNULL(CONVERT(VARCHAR, @val_poidsNet), 'NULL')	
						+ ', @idBobine = ' + ISNULL(CONVERT(VARCHAR, @idBobine), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace

					-- Modification du poids
					EXEC @retour = dbo.SPC_CHG_MODIFIER_POIDS_NET @v_idBobine = @idBobine, @v_poidsNet = @val_poidsNet
					IF(@retour <> @CODE_OK)
					BEGIN
						SET @trace = 'SPC_CHG_MODIFIER_POIDS_NET ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						SET @trace = @procStock + '/' + @trace
						EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
													@v_log_idlog = 'ERREUR',
													@v_trace = @trace
					END

					-- Valider Bobine
					SELECT @val_destination = dbo.SPC_DMD_APPRO_DEMAC.SDD_ROTATIVE FROM dbo.SPC_DMD_APPRO_DEMAC WHERE dbo.SPC_DMD_APPRO_DEMAC.SDD_IDBOBINE = @idBobine

					EXEC @retour = dbo.SPC_DMC_VALIDERBOBINE @v_idligne = @ligneDemaculage, @v_destination = @val_destination, @v_idBobine = @idBobine
					IF(@retour <> @CODE_OK)
					BEGIN
						SET @trace = 'SPC_DMC_VALIDERBOBINE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						SET @trace = @procStock + '/' + @trace
						EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
													@v_log_idlog = 'ERREUR',
													@v_trace = @trace
					END
				END	
				-- Infos Bobine Station Intermédiaire
				ELSE IF(@action = 35)
				BEGIN
					-- Récupération des informations liées à l'action
					SELECT
						@val_newBobine = NEW_BOBINE.VAU_VALEUR,
						@val_idBobine1 = BOBINE1.VAU_VALEUR,
						@val_idBobine2 = BOBINE2.VAU_VALEUR
					FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
					JOIN dbo.INT_VARIABLE_AUTOMATE NEW_BOBINE
						ON NEW_BOBINE.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_NEWBOBINE
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE1
						ON BOBINE1.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE2
						ON BOBINE2.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2
					WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE = @v_idVariableAutomate

					-- Reconstitution de l'identifiant de la bobine
					EXEC @retour = dbo.SPC_DMC_SET_IDBOBINE @v_idBobine = @idBobine OUT, @v_idBobineToChar1 = @val_idBobine1, @v_idBobineToChar2 = @val_idBobine2

					SET @trace = 'Action  ' + ISNULL(CONVERT(VARCHAR, @actionLibelle), 'NULL')	
						+ ', @ligneDemaculage = ' + ISNULL(CONVERT(VARCHAR, @ligneDemaculage), 'NULL')	
						+ ', @val_newBobine = ' + ISNULL(CONVERT(VARCHAR, @val_newBobine), 'NULL')	
						+ ', @idBobine = ' + ISNULL(CONVERT(VARCHAR, @idBobine), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace
					-- Récupération de l'adresse du poste de démaculage
					SELECT
						@idSysteme = dbo.INT_ADRESSE.ADR_IDSYSTEME,
						@idBase = dbo.INT_ADRESSE.ADR_IDBASE,
						@idSousBase = dbo.INT_ADRESSE.ADR_IDSOUSBASE
					FROM dbo.INT_ADRESSE
					WHERE dbo.INT_ADRESSE.ADR_IDTYPEMAGASIN = 2
					AND dbo.INT_ADRESSE.ADR_MAGASIN = 3
					AND dbo.INT_ADRESSE.ADR_COTE = 1
					AND dbo.INT_ADRESSE.ADR_COULOIR = @ligneDemaculage
					AND dbo.INT_ADRESSE.ADR_RACK = 1
					

					SET @trace = 'Poste Intermédiaire  '
						+ ', @idSysteme = ' + ISNULL(CONVERT(VARCHAR, @idSysteme), 'NULL')	
						+ ', @idBase = ' + ISNULL(CONVERT(VARCHAR, @idBase), 'NULL')	
						+ ', @idSousBase = ' + ISNULL(CONVERT(VARCHAR, @idSousBase), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace

					-- Transfert de la charge sur l'adresse du poste de démaculage
					EXEC @retour = dbo.INT_TRANSFERCHARGE	@v_chg_idcharge = @idBobine,
															@v_adr_idsysteme_depose = @idSysteme,
															@v_adr_idbase_depose = @idBase,
															@v_adr_idsousbase_depose = @idSousBase,
															@v_chg_orientation_depose = 0,
															@v_forcage = 1 -- On force pour éviter la désynchro
					IF(@retour <> @CODE_OK)
					BEGIN
						SET @trace = 'INT_TRANSFERCHARGE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						SET @trace = @procStock + '/' + @trace
						EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
													@v_log_idlog = 'ERREUR',
													@v_trace = @trace
					END
					ELSE
					BEGIN
						SET @trace = 'Bobine sur Poste Demaculage  '
						SET @trace = @procStock + '/' + @trace
						EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
													@v_log_idlog = 'DEBUG',
													@v_trace = @trace
					END
				END	
				-- Infos Bobine Station TRR
				ELSE IF(@action = 51)
				BEGIN
					-- Récupération des informations liées à l'action
					SELECT
						@val_type = ISNULL(TYPE_CHARGE.VAU_VALEUR, 1), -- Si NULL, on est sur la ligne 5 => Forcément 1 - Bobine
						@val_idBobine1 = BOBINE1.VAU_VALEUR,
						@val_idBobine2 = BOBINE2.VAU_VALEUR
					FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
					LEFT OUTER JOIN dbo.INT_VARIABLE_AUTOMATE TYPE_CHARGE -- Left Outer car la variable Type n'existe pas sur la ligne 5
						ON TYPE_CHARGE.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_TYPE
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE1
						ON BOBINE1.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1
					JOIN dbo.INT_VARIABLE_AUTOMATE BOBINE2
						ON BOBINE2.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2
					WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE = @v_idVariableAutomate

					-- Reconstitution de l'identifiant de la bobine
					EXEC @retour = dbo.SPC_DMC_SET_IDBOBINE @v_idBobine = @idBobine OUT, @v_idBobineToChar1 = @val_idBobine1, @v_idBobineToChar2 = @val_idBobine2

					SET @trace = 'Action  ' + ISNULL(CONVERT(VARCHAR, @actionLibelle), 'NULL')	
						+ ', @ligneDemaculage = ' + ISNULL(CONVERT(VARCHAR, @ligneDemaculage), 'NULL')	
						+ ', @val_type = ' + ISNULL(CONVERT(VARCHAR, @val_type), 'NULL')	
						+ ', @idBobine = ' + ISNULL(CONVERT(VARCHAR, @idBobine), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace
					
					-- Récupération de l'adresse du poste de Sortie
					SELECT
						@idSysteme = dbo.INT_ADRESSE.ADR_IDSYSTEME,
						@idBase = dbo.INT_ADRESSE.ADR_IDBASE,
						@idSousBase = dbo.INT_ADRESSE.ADR_IDSOUSBASE
					FROM dbo.INT_ADRESSE
					WHERE dbo.INT_ADRESSE.ADR_IDTYPEMAGASIN = 2
					AND dbo.INT_ADRESSE.ADR_MAGASIN = 3
					AND dbo.INT_ADRESSE.ADR_COTE = 3
					AND dbo.INT_ADRESSE.ADR_COULOIR = @ligneDemaculage
					
					SET @trace = 'Poste TRR  '
						+ ', @idSysteme = ' + ISNULL(CONVERT(VARCHAR, @idSysteme), 'NULL')	
						+ ', @idBase = ' + ISNULL(CONVERT(VARCHAR, @idBase), 'NULL')	
						+ ', @idSousBase = ' + ISNULL(CONVERT(VARCHAR, @idSousBase), 'NULL')	
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace

					-- Transfert de la charge sur l'adresse du poste de démaculage
					EXEC @retour = dbo.INT_TRANSFERCHARGE	@v_chg_idcharge = @idBobine,
															@v_adr_idsysteme_depose = @idSysteme,
															@v_adr_idbase_depose = @idBase,
															@v_adr_idsousbase_depose = @idSousBase,
															@v_chg_orientation_depose = 0,
															@v_forcage = 1 -- On force pour éviter la désynchro
					IF(@retour <> @CODE_OK)
					BEGIN
						SET @trace = 'INT_TRANSFERCHARGE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						SET @trace = @procStock + '/' + @trace
						EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
													@v_log_idlog = 'ERREUR',
													@v_trace = @trace
					END
					ELSE
					BEGIN
						SET @trace = 'Charge sur Poste TRR  '
						SET @trace = @procStock + '/' + @trace
						EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
													@v_log_idlog = 'DEBUG',
													@v_trace = @trace
					END
				END
			END
		END 

	END

	RETURN @retour
 	

END



