SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Menu de création d'une Demande de Rangement
			@v_rotative			: Numéro de la rotative
			@v_idSysteme		: Base de la base de prise
			@v_idBase			: Sous base de la base de prise
			@v_idSousBase		: Système de la base de prise
			@v_laize			: laize de la bobine
			@v_diametre			: Diamètre de la bobine
			@v_grammage			: Grammage de la bobine
			@v_idFournisseur	: Identifiant du Fournisseur (par défaut 0)
			@v_priorite			: Priorité de la demande (opar défaut 0)
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_DRR_CREER_DEMANDE]
	@v_idDemande		varchar(20) output,
	@v_rotative			int,
	@v_idSysteme		bigint,
	@v_idBase			bigint,
	@v_idSousBase		bigint,
	@v_laize			int,
	@v_diametre			int,
	@v_grammage			NUMERIC(4,2),
	@v_idFournisseur	int = 0,
	@v_priorite			int = 0
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @COMPTEUR_DMD_RACK_ROTATIVE int = 3
DECLARE @ETAT_DMD_NOUVELLE INT = 0

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Appro Rack Rotative'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

declare @idDemande varchar(20)
declare @adresse varchar(8000)

	/*Comment renseigne t'on l'id demande*/
	-- Récupération de l'identifiant dans une table de paramétrage + Ajout Préfixe "RR_"
	/*Quels checks sont a réaliser?*/
	-- Vérification données d'entrée : Rotative, Laize, Diamètre, Grammage, Case, Fournisseur, Priorité
	-- Vérification Rotative
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
	-- Vérification Case (Adresse Rack Rotative)
	IF NOT EXISTS (	SELECT
					1
				FROM dbo.INT_ADRESSE
				WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSysteme
				AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBase
				AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBase
				AND dbo.INT_ADRESSE.ADR_IDTYPEMAGASIN = 3
				AND dbo.INT_ADRESSE.ADR_MAGASIN = 5
				AND dbo.INT_ADRESSE.ADR_IDETAT_OCCUPATION = 1
				AND dbo.INT_ADRESSE.ADR_AUTORISATIONDEPOSE = 1)
	BEGIN
		SELECT
			@adresse = dbo.INT_ADRESSE.ADR_ADRESSE
		FROM dbo.INT_ADRESSE
		WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSysteme
		AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBase
		AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBase

		SET @trace = 'Nouvelle Demande, la case n existe pas ou n est pas vide ou interdite en dépose : ' 
					+ ', @v_idSysteme:' + ISNULL(CONVERT(VARCHAR, @v_idSysteme), 'NULL')
					+ ', @v_idBase:' + ISNULL(CONVERT(VARCHAR, @v_idBase), 'NULL')
					+ ', @v_idSousBase:' + ISNULL(CONVERT(VARCHAR, @v_idSousBase), 'NULL')
					+ ', @adresse:' + ISNULL(CONVERT(VARCHAR, @adresse), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END
	-- Vérification Fournisseur
	IF(@v_idFournisseur IS NULL)
	BEGIN
		SET @v_idFournisseur = 0
	END
	IF NOT EXISTS(SELECT 1 FROM dbo.SPC_CHG_FOURNISSEUR where dbo.SPC_CHG_FOURNISSEUR.SCF_IDFOURNISSEUR = @v_idFournisseur AND @v_idFournisseur <> 0)
	BEGIN
		SET @trace = 'Nouvelle Demande, le fournisseur n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_idFournisseur), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END

	-- Vérification Priorité
	IF(@v_priorite IS NULL)
	BEGIN
		SET @v_priorite = 0
	END

	-- Vérification Demande existante
	IF EXISTS (	SELECT
					1
				FROM dbo.SPC_DMD_APPRO_RACK_ROTATIVE
				WHERE dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_IDSYSTEME = @v_idSysteme
				AND dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_IDBASE = @v_idBase
				AND dbo.SPC_DMD_APPRO_RACK_ROTATIVE.SDR_IDSOUSBASE = @v_idSousBase)
	BEGIN
		SET @trace = 'Nouvelle Demande, une demande existe pour cette case'
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
		-- Récupération de l'identifiant de la demande
		EXEC @retour = dbo.SPC_DMD_CREER_ID @v_idCompteur = @COMPTEUR_DMD_RACK_ROTATIVE, @v_idDemande = @idDemande OUT
		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'SPC_DMD_CREER_ID ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						+ ', @v_idCompteur:' + ISNULL(CONVERT(VARCHAR, @COMPTEUR_DMD_RACK_ROTATIVE), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
		END

		IF(@retour = @CODE_OK)
		BEGIN
			INSERT INTO [dbo].[SPC_DMD_APPRO_RACK_ROTATIVE] ([SDR_IDDEMANDE]
			, [SDR_ROTATIVE]
			, [SDR_IDSYSTEME]
			, [SDR_IDBASE]
			, [SDR_IDSOUSBASE]
			, [SDR_LAIZE]
			, [SDR_DIAMETRE]
			, [SDR_GRAMMAGE]
			, [SDR_IDFOURNISSEUR]
			, [SDR_ETAT]
			, [SDR_DATE]
			, [SDR_PRIORITE])
				VALUES (@idDemande, @v_rotative, @v_idSysteme, @v_idBase, @v_idSousBase, @v_laize, @v_diametre, @v_grammage, @v_idFournisseur, @ETAT_DMD_NOUVELLE, GETDATE(), @v_priorite)

			SET @retour = @@ERROR
	
			IF(@retour <> @CODE_OK)
			BEGIN
				SET @trace = 'Erreur à la création de la demande : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'ERREUR',
											@v_trace = @trace
			END
			ELSE
			BEGIN
				SELECT
					@adresse = dbo.INT_ADRESSE.ADR_ADRESSE
				FROM dbo.INT_ADRESSE
				WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSysteme
				AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBase
				AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBase

				SET @trace = 'Demande Approvisionnement Rack Rotative crée : '
							+ ', @idDemande:' + ISNULL(CONVERT(VARCHAR, @idDemande), 'NULL')
							+ ', @v_rotative:' + ISNULL(CONVERT(VARCHAR, @v_rotative), 'NULL')
							+ ', @v_idSysteme:' + ISNULL(CONVERT(VARCHAR, @v_idSysteme), 'NULL')
							+ ', @v_idBase:' + ISNULL(CONVERT(VARCHAR, @v_idBase), 'NULL')
							+ ', @v_idSousBase:' + ISNULL(CONVERT(VARCHAR, @v_idSousBase), 'NULL')
							+ ', @adresse:' + ISNULL(CONVERT(VARCHAR, @adresse), 'NULL')
							+ ', @v_laize:' + ISNULL(CONVERT(VARCHAR, @v_laize), 'NULL')
							+ ', @v_diametre:' + ISNULL(CONVERT(VARCHAR, @v_diametre), 'NULL')
							+ ', @v_grammage:' + ISNULL(CONVERT(VARCHAR, @v_grammage), 'NULL')
							+ ', @v_idFournisseur:' + ISNULL(CONVERT(VARCHAR, @v_idFournisseur), 'NULL')
							+ ', @v_priorite:' + ISNULL(CONVERT(VARCHAR, @v_priorite), 'NULL')
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'DEBUG',
											@v_trace = @trace
			END
		END
	END

	IF(@retour = @CODE_OK)
	BEGIN
		SET @v_idDemande = @idDemande

		SET @trace = 'Identifiant retourné : '
							+ ', @v_idDemande:' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace

		-- Trace Historique
		EXEC dbo.SPC_DRR_INSERER_TRACE @v_idDemande = @v_idDemande
	END
	
	

	RETURN @retour
 	

END

