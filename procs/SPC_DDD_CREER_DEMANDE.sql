SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Menu de création d'une Demande de Rangement
-- @v_rotative			: Rotative demande
-- @v_laize				: Laise
-- @v_diametre			: Diamètre
-- @v_grammage			: Grammage
-- @v_idFournisseur		: Fournisseur
-- @v_priorite			: priorité de la mission
-- @v_dmdEmettrice		: Demande Emettrice
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDD_CREER_DEMANDE]
	@v_rotative			int,
	@v_laize			int,
	@v_diametre			int,
	@v_grammage			NUMERIC(5,2),
	@v_idFournisseur	int,
	@v_priorite			int,
	@v_dmdEmettrice		varchar(20)
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @ETAT_DMD_NOUVELLE INT = 0

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Appro Demac'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @COMPTEUR_DMD_APPRO_DEMAC int = 2
declare @v_idDemande varchar(20)

	/*Quels checks sont a réaliser?*/
	-- Vérification données d'entrée : Rotative, Laize, Diamètre, Grammage
	IF NOT EXISTS(SELECT 1 FROM dbo.SPC_ROTATIVE WHERE dbo.SPC_ROTATIVE.SRO_IDROTATIVE = @v_rotative)
	BEGIN
		SET @trace = 'Nouvelle Demande, la rotative n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_rotative), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END
	-- Vérification Laize
	IF NOT EXISTS(SELECT 1 FROM dbo.SPC_CHG_LAIZE WHERE dbo.SPC_CHG_LAIZE.SCL_LAIZE = @v_laize)
	BEGIN
		SET @trace = 'Nouvelle Demande, la laize n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_laize), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END
	-- Vérification Diamètre
	IF NOT EXISTS(SELECT 1 FROM dbo.SPC_CHG_DIAMETRE WHERE dbo.SPC_CHG_DIAMETRE.SCD_DIAMETRE = @v_diametre)
	BEGIN
		SET @trace = 'Nouvelle Demande, le diamètre n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_diametre), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END
	-- Vérification Grammage
	IF NOT EXISTS(SELECT 1 FROM dbo.SPC_CHG_GRAMMAGE WHERE dbo.SPC_CHG_GRAMMAGE.SCG_GRAMMAGE = @v_grammage)
	BEGIN
		SET @trace = 'Nouvelle Demande, le grammage n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_grammage), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END
	
	IF(@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'Demande Erronée '
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	END
	
	IF(@retour = @CODE_OK)
	BEGIN
		-- Récupération de l'identifiant dans une table de paramétrage + Ajout Préfixe "AD_"
		EXEC @retour = dbo.SPC_DMD_CREER_ID @v_idCompteur = @COMPTEUR_DMD_APPRO_DEMAC, @v_idDemande = @v_idDemande OUT
		
		INSERT INTO [dbo].[SPC_DMD_APPRO_DEMAC] ([SDD_IDDEMANDE], [SDD_ROTATIVE], [SDD_LAIZE], [SDD_DIAMETRE]
		, [SDD_GRAMMAGE], [SDD_IDFOURNISSEUR], [SDD_ETAT], [SDD_DATE]
		, [SDD_PRIORITE], [SDD_IDDEMANDE_EMETTRICE])
			VALUES (@v_idDemande, @v_rotative, @v_laize, @v_diametre, @v_grammage, @v_idFournisseur, @ETAT_DMD_NOUVELLE, GETDATE(), @v_priorite, @v_dmdEmettrice)
		SET @retour = @@ERROR
		
		-- Ajout historique
		IF(@retour = @CODE_OK)
		BEGIN
			SET @trace = 'Identifiant retourné : '
								+ ', @v_idDemande:' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'DEBUG',
										@v_trace = @trace
			EXEC SPC_DDD_INSERER_TRACE @v_idDemande = @v_idDemande
		END

		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'Erreur à la création de la demande : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
		END
	END
	
	RETURN @retour

END

