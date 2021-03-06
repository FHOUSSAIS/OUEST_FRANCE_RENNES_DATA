SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gérer les Demandes d'approvisionnements du RACK ROTATIVE
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DRR_GESTION]
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12
DECLARE @ETAT_DMD_REFUSEE		INT = 13

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Appro Rack Rotative'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @dmd_idDemande VARCHAR(20)
DECLARE @dmd_rotative INT
DECLARE @dmd_laize INT
DECLARE @dmd_diametre INT
DECLARE @dmd_grammage NUMERIC(4,2)
DECLARE @dmd_idFournisseur INT
DECLARE @dmd_priorite INT
DECLARE @dmd_etat INT

SET @trace = 'Gestion des demandes'
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

/*---------------------------------------------------
	Gestion des Nouvelles de Demande
	Création de la demande Appro Démac associée
---------------------------------------------------*/
DECLARE C_DMD_NOUVELLES CURSOR LOCAL FAST_FORWARD FOR
	SELECT
		dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_IDDEMANDE,
		dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_ROTATIVE,
		dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_LAIZE,
		dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_DIAMETRE,
		dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_GRAMMAGE,
		dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_IDFOURNISSEUR,
		dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_PRIORITE
	FROM dbo.SPC_DMD_APPRO_RACK_ROTATIVE
	WHERE dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_ETAT = @ETAT_DMD_NOUVELLE
OPEN C_DMD_NOUVELLES
FETCH NEXT FROM C_DMD_NOUVELLES into @dmd_idDemande, @dmd_rotative, @dmd_laize, @dmd_diametre, @dmd_grammage, @dmd_idFournisseur, @dmd_priorite
WHILE(@@fetch_status = 0)
BEGIN
	SET @trace = 'Traitement Nouvelle Demande ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
			+ ', @dmd_rotative = ' + ISNULL(CONVERT(VARCHAR, @dmd_rotative), 'NULL')	
			+ ', @dmd_laize = ' + ISNULL(CONVERT(VARCHAR, @dmd_laize), 'NULL')	
			+ ', @dmd_diametre = ' + ISNULL(CONVERT(VARCHAR, @dmd_diametre), 'NULL')	
			+ ', @dmd_grammage = ' + ISNULL(CONVERT(VARCHAR, @dmd_grammage), 'NULL')	
			+ ', @dmd_idFournisseur = ' + ISNULL(CONVERT(VARCHAR, @dmd_idFournisseur), 'NULL')	
			+ ', @dmd_priorite = ' + ISNULL(CONVERT(VARCHAR, @dmd_priorite), 'NULL')	
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace

	-- Désactiver en attendant Dev
	/*EXEC @retour = dbo.SPC_DDD_CREER_DEMANDE	@v_rotative = @dmd_rotative,
												@v_laize = @dmd_laize,
												@v_diametre = @dmd_diametre,
												@v_grammage = @dmd_grammage,
												@v_idFournisseur = @dmd_idFournisseur,
												@v_priorite = @dmd_priorite,
												@v_dmdEmettrice = @dmd_idDemande
	*/
	SET @retour = @CODE_OK -- A retirer après avoir décommenter l'appel à SPC_DDD_CREER_DEMANDE

	IF (@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'Erreur a la création de la demande Appro Démac ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @dmd_etat = @ETAT_DMD_REFUSEE
	END
	ELSE
	BEGIN
		SET @trace = 'La demande Appro Démac a été créée ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
		SET @dmd_etat = @ETAT_DMD_EN_ATTENTE
	END

	EXEC @retour = dbo.SPC_DRR_MODIFIER_DEMANDE @v_idDemande = @dmd_idDemande, @v_etat = @dmd_etat

	IF (@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'Erreur a la mise à jour de la demande' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	END
	ELSE
	BEGIN
		SET @trace = 'La demande a été mise à jour ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
	END

	FETCH NEXT FROM C_DMD_NOUVELLES into @dmd_idDemande, @dmd_rotative, @dmd_laize, @dmd_diametre, @dmd_grammage, @dmd_idFournisseur, @dmd_priorite	
END
CLOSE C_DMD_NOUVELLES
DEALLOCATE C_DMD_NOUVELLES

DECLARE C_DMD_AUTRE CURSOR LOCAL FAST_FORWARD FOR
	SELECT
		dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_IDDEMANDE,
		dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_ETAT
	FROM dbo.SPC_DMD_APPRO_RACK_ROTATIVE
	WHERE dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_ETAT <> @ETAT_DMD_NOUVELLE
OPEN C_DMD_AUTRE
FETCH NEXT FROM C_DMD_AUTRE into @dmd_idDemande, @dmd_etat
WHILE(@@fetch_status = 0)
BEGIN
	/*---------------------------------------------------
		Gestion des Demandes EN ATTENTE
		Vérification Demande Démac Associée Valide
	---------------------------------------------------*/
	IF(@dmd_etat = @ETAT_DMD_EN_ATTENTE)
	BEGIN
		SET @trace = 'Traitement Demande En Attente' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace

		-- Test Existance Demande Appro Démac
		--IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_APPRO_DEMAC WHERE dbo.SPC_DMD_APPRO_DEMAC.SDD_IDDEMANDE_EMETTRICE = @dmd_idDemande)
		IF NOT EXISTS(SELECT 1) -- A remplacer par ligne au dessus une fois l'appro demac finalisée
		BEGIN
			SET @trace = 'pas de demande Appro Démac Associée' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')	
						+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @ETAT_DMD_EN_ATTENTE), 'NULL')	
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'DEBUG',
										@v_trace = @trace

			EXEC @retour = dbo.SPC_DRR_MODIFIER_DEMANDE @v_idDemande = @dmd_idDemande, @v_etat = @ETAT_DMD_NOUVELLE

			IF (@retour <> @CODE_OK)
			BEGIN
				SET @trace = 'Erreur a la mise à jour de la demande' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'ERREUR',
											@v_trace = @trace
			END
			ELSE
			BEGIN
				SET @trace = 'La demande a été mise à jour ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'DEBUG',
											@v_trace = @trace
			END
		END
	END
	
	/*---------------------------------------------------
		Gestion des Demandes EN COURS
		Vérification Demande TRR Associée Valide
	---------------------------------------------------*/
	ELSE IF(@dmd_etat = @ETAT_DMD_EN_COURS)
	BEGIN
		SET @trace = 'Traitement Demande En Cours' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace

		-- Test Existance Demande TRR
	
		IF NOT EXISTS(SELECT 1)
		BEGIN
			SET @trace = 'pas de demande TRR Associée / Suspension de la demande' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')	
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'DEBUG',
										@v_trace = @trace
		
			-- Modification de la Demande : Etat SUSPENDUE
			EXEC @retour = dbo.SPC_DRR_MODIFIER_DEMANDE @v_idDemande = @dmd_idDemande, @v_etat = @ETAT_DMD_SUSPENDUE

			IF (@retour <> @CODE_OK)
			BEGIN
				SET @trace = 'Erreur a la mise à jour de la demande' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'ERREUR',
											@v_trace = @trace
			END
			ELSE
			BEGIN
				SET @trace = 'La demande a été mise à jour' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'DEBUG',
											@v_trace = @trace
			END
		END
	END

	/*---------------------------------------------------
		Gestion des Demandes TERMINEE / ANNULEE / REFUSEE
		Suppression des demandes
	---------------------------------------------------*/
	ELSE IF(@dmd_etat IN (@ETAT_DMD_TERMINEE, @ETAT_DMD_REFUSEE, @ETAT_DMD_REFUSEE))
	BEGIN
		SET @trace = 'Traitement Demande A Supprimer' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace

		-- Suppresssion de la Demande
		EXEC @retour = dbo.SPC_DRR_SUPPRIMER_DEMANDE @v_idDemande = @dmd_idDemande

		IF (@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'Erreur a la suppression à jour de la demande ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
		END
		ELSE
		BEGIN
			SET @trace = 'La demande a été supprimée ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'DEBUG',
										@v_trace = @trace
		END
	END
	/*---------------------------------------------------
		Gestion des Demandes SUSPENDUE
		Uniquement à titre informatif
	---------------------------------------------------*/
	ELSE IF(@dmd_etat = @ETAT_DMD_SUSPENDUE)
	BEGIN
		SET @trace = 'Traitement Demande Suspendue ' + ISNULL(CONVERT(VARCHAR, @dmd_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
	END

	FETCH NEXT FROM C_DMD_AUTRE into @dmd_idDemande, @dmd_etat
END
CLOSE C_DMD_AUTRE
DEALLOCATE C_DMD_AUTRE

RETURN @retour
END

