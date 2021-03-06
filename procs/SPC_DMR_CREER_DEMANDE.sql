SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Menu de création d'une Demande de Mouvement TRR
			@v_idSystemePrise	  : Système de la base de prise
			@v_idBasePrise		  : Base de la base de prise
			@v_idSousBasePrise	  : Sous base de la base de prise
			@v_idSystemeDepose	  : Système de la base de dépose
			@v_idBaseDepose		  : Base de la base de dépose
			@v_idSousBaseDepose	  : Sous Base de la base dépose
			@v_priorite			  : Priorité de la demande (opar défaut 0)
			@v_idDemandeEmettrice : Demande Emettrice
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_DMR_CREER_DEMANDE]
	@v_idDemande			varchar(20) output,
	@v_idSystemePrise		bigint,
	@v_idBasePrise			bigint,
	@v_idSousBasePrise		bigint,
	@v_idSystemeDepose		bigint,
	@v_idBaseDepose			bigint,
	@v_idSousBaseDepose		bigint,
	@v_priorite				int = 0,
	@v_idDemandeEmettrice	varchar(20)
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @COMPTEUR_DMD_MOUVEMENT_TRR int = 4
DECLARE @ETAT_DMD_NOUVELLE INT = 0

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Mouvement TRR'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

declare @idDemande VARCHAR(20)
declare @adressePrise VARCHAR(8000)
declare @adresseDepose VARCHAR(8000)

	-- Vérification données d'entrée : Base de Prise / Base de Dépose / Priorité 
	-- Vérification Case Prise (Adresse Rack Rotative)
	IF NOT EXISTS (	SELECT
					1
				FROM dbo.INT_ADRESSE
				WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSystemePrise
				AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBasePrise
				AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBasePrise
				AND dbo.INT_ADRESSE.ADR_IDTYPEMAGASIN = 3
				AND dbo.INT_ADRESSE.ADR_MAGASIN = 5
				AND dbo.INT_ADRESSE.ADR_IDETAT_OCCUPATION = 3
				AND dbo.INT_ADRESSE.ADR_AUTORISATIONPRISE = 1)
	BEGIN
		SELECT
			@adressePrise = dbo.INT_ADRESSE.ADR_ADRESSE
		FROM dbo.INT_ADRESSE
		WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSystemePrise
		AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBasePrise
		AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBasePrise

		SET @trace = 'Nouvelle Demande, la case prise n existe pas ou n est pas occupée ou interdite en prise : ' 
					+ ', @v_idSysteme:' + ISNULL(CONVERT(VARCHAR, @v_idSystemePrise), 'NULL')
					+ ', @v_idBase:' + ISNULL(CONVERT(VARCHAR, @v_idBasePrise), 'NULL')
					+ ', @v_idSousBase:' + ISNULL(CONVERT(VARCHAR, @v_idSousBasePrise), 'NULL')
					+ ', @adresse:' + ISNULL(CONVERT(VARCHAR, @adressePrise), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END
	-- Vérification Case Dépose (Adresse Rack Rotative)
	IF NOT EXISTS (	SELECT
					1
				FROM dbo.INT_ADRESSE
				WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSystemeDepose
				AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBaseDepose
				AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBaseDepose
				AND dbo.INT_ADRESSE.ADR_IDTYPEMAGASIN = 3
				AND dbo.INT_ADRESSE.ADR_MAGASIN = 5
				AND dbo.INT_ADRESSE.ADR_IDETAT_OCCUPATION = 1
				AND dbo.INT_ADRESSE.ADR_AUTORISATIONDEPOSE = 1)
	BEGIN
		SELECT
			@adresseDepose = dbo.INT_ADRESSE.ADR_ADRESSE
		FROM dbo.INT_ADRESSE
		WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSystemeDepose
		AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBaseDepose
		AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBaseDepose

		SET @trace = 'Nouvelle Demande, la case depose n existe pas ou n est pas vide ou interdite en dépose : ' 
					+ ', @v_idSysteme:' + ISNULL(CONVERT(VARCHAR, @v_idSystemeDepose), 'NULL')
					+ ', @v_idBase:' + ISNULL(CONVERT(VARCHAR, @v_idBaseDepose), 'NULL')
					+ ', @v_idSousBase:' + ISNULL(CONVERT(VARCHAR, @v_idSousBaseDepose), 'NULL')
					+ ', @adresse:' + ISNULL(CONVERT(VARCHAR, @adresseDepose), 'NULL')
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
			FROM dbo.SPC_DMD_MOUVEMENT_TRR
			WHERE (	dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSYSTEME_PRISE = @v_idSystemePrise
					AND dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDBASE_PRISE = @v_idBasePrise
					AND dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSOUSBASE_PRISE = @v_idSousBasePrise)
			OR (	dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSYSTEME_DEPOSE = @v_idSystemeDepose
					AND dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDBASE_DEPOSE = @v_idBaseDepose
					AND dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDSOUSBASE_DEPOSE = @v_idSousBaseDepose))
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
		EXEC @retour = dbo.SPC_DMD_CREER_ID @v_idCompteur = @COMPTEUR_DMD_MOUVEMENT_TRR, @v_idDemande = @idDemande OUT
		IF(@retour <> @CODE_OK)
		BEGIN
			SET @trace = 'SPC_DMD_CREER_ID ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
						+ ', @v_idCompteur:' + ISNULL(CONVERT(VARCHAR, @COMPTEUR_DMD_MOUVEMENT_TRR), 'NULL')
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
		END

		INSERT INTO [dbo].[SPC_DMD_MOUVEMENT_TRR]
				   ([SDM_IDDEMANDE]
				   ,[SDM_IDSYSTEME_PRISE]
				   ,[SDM_IDBASE_PRISE]
				   ,[SDM_IDSOUSBASE_PRISE]
				   ,[SDM_IDSYSTEME_DEPOSE]
				   ,[SDM_IDBASE_DEPOSE]
				   ,[SDM_IDSOUSBASE_DEPOSE]
				   ,[SDM_ETAT]
				   ,[SDM_DATE]
				   ,[SDM_PRIORITE]
				   ,[SDM_IDDEMANDE_EMETTRICE])
			 VALUES
				   ( @idDemande
				   , @v_idSystemePrise
				   , @v_idBasePrise
				   , @v_idSousBasePrise
				   , @v_idSystemeDepose
				   , @v_idBaseDepose
				   , @v_idSousBaseDepose
				   , @ETAT_DMD_NOUVELLE
				   , GETDATE()
				   , @v_priorite
				   , @v_idDemandeEmettrice)

		IF(@retour = @CODE_OK)
		BEGIN
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
					@adressePrise = dbo.INT_ADRESSE.ADR_ADRESSE
				FROM dbo.INT_ADRESSE
				WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSystemePrise
				AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBasePrise
				AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBasePrise

				SELECT
					@adresseDepose = dbo.INT_ADRESSE.ADR_ADRESSE
				FROM dbo.INT_ADRESSE
				WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSystemeDepose
				AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBaseDepose
				AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBaseDepose

				SET @trace = 'Demande Approvisionnement Mouvement TRR : '
							+ ', @idDemande:' + ISNULL(CONVERT(VARCHAR, @idDemande), 'NULL')
							+ ', @v_idSystemePrise:' + ISNULL(CONVERT(VARCHAR, @v_idSystemePrise), 'NULL')
							+ ', @v_idBasePrise:' + ISNULL(CONVERT(VARCHAR, @v_idBasePrise), 'NULL')
							+ ', @v_idSousBasePrise:' + ISNULL(CONVERT(VARCHAR, @v_idSousBasePrise), 'NULL')
							+ ', @adressePrise:' + ISNULL(CONVERT(VARCHAR, @adressePrise), 'NULL')
							+ ', @v_idSystemeDepose:' + ISNULL(CONVERT(VARCHAR, @v_idSystemeDepose), 'NULL')
							+ ', @v_idBaseDepose:' + ISNULL(CONVERT(VARCHAR, @v_idBaseDepose), 'NULL')
							+ ', @v_idSousBaseDepose:' + ISNULL(CONVERT(VARCHAR, @v_idSousBaseDepose), 'NULL')
							+ ', @adresse:' + ISNULL(CONVERT(VARCHAR, @adresseDepose), 'NULL')
							+ ', @v_priorite:' + ISNULL(CONVERT(VARCHAR, @v_priorite), 'NULL')
							+ ', @v_idDemandeEmettrice:' + ISNULL(CONVERT(VARCHAR, @v_idDemandeEmettrice), 'NULL')
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
		EXEC dbo.SPC_DMR_INSERER_TRACE @v_idDemande = @v_idDemande
	END
	
	

	RETURN @retour
 	

END

