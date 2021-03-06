SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Traitement de l'Evènement Compte Rendu Exécution de Tache
--				
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMC_EVT_CRD_EXECUTIONTACHE] 
	@v_action int,
	@v_idMission int,
	@v_idDemande varchar(20),
	@v_statutPrimaire int,
	@v_description int,
	@v_idAgv int,
	@v_idCharge int,
	@v_idSysteme bigint,
	@v_idBase bigint,
	@v_idSousBase bigint,
	@v_offsetProfondeur int,
	@v_offsetNiveau int,
	@v_offsetColonne int
AS
BEGIN
DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @TAC_ACTION_PRISE INT = 2
DECLARE	@TAC_ACTION_DEPOSE INT = 4
DECLARE @DESC_ERREUR_ACTIONPRIMAIRE INT = 1
DECLARE @DESC_ERREUR_MOUVEMENT INT = 2
DECLARE @DESC_EXEC_AUTO INT = 3
DECLARE @DESC_EXEC_MANU INT = 4		

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demaculeuse'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @tac_action VARCHAR(8000)
DECLARE @tac_adresse VARCHAR(8000)
DECLARE @idLigne INT
DECLARE @idSensEnroulement INT
		
-- Surcharge du Moniteur
SELECT @tac_action = dbo.INT_GETLIBELLE( ACT_IdTraduction, 'fra' ) FROM ACTION where ACT_IdAction = @v_action
SET @procStock = @procStock + ' ' + ISNULL( CONVERT( VARCHAR, @v_idMission ), 'null' ) + ' ' + @tac_action

--Demande de réorga stock?
IF EXISTS (SELECT 1 from SPC_DMD_REORGA_STOCK_GENERAL where SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDDEMANDE = @v_idDemande)
BEGIN
-- Vérification Adresse Exécution Démaculeuse
IF EXISTS(	SELECT
				1
			FROM dbo.INT_ADRESSE
			WHERE dbo.INT_ADRESSE.ADR_MAGASIN = 3
			AND dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSysteme
			AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBase
			AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBase)
BEGIN
	SELECT @tac_adresse = dbo.INT_ADRESSE.ADR_ADRESSE FROM dbo.INT_ADRESSE WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSysteme AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBase and dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBase

	SET @trace = '@v_action ' + ISNULL( CONVERT( VARCHAR, @v_action ), 'null' ) 
			+ ' / @v_idMission :' + ISNULL( CONVERT( VARCHAR, @v_idMission ), 'null' )
			+ ' / @v_idDemande : ' + ISNULL( CONVERT( VARCHAR, @v_idDemande ), 'null' )
			+ ' / @v_statutPrimaire : ' + ISNULL( CONVERT( VARCHAR, @v_statutPrimaire ), 'null' )
			+ ' / @v_description : ' + ISNULL( CONVERT( VARCHAR, @v_description ), 'null' )
			+ ' / @v_idAgv : ' + ISNULL( CONVERT( VARCHAR, @v_idAgv ), 'null' )
			+ ' / @v_idCharge : ' + ISNULL( CONVERT( VARCHAR, @v_idCharge ), 'null' )
			+ ' / @v_idSysteme : ' + ISNULL( CONVERT( VARCHAR, @v_idSysteme ), 'null' )
			+ ' / @v_idBase : ' + ISNULL( CONVERT( VARCHAR, @v_idBase ), 'null' )
			+ ' / @v_idSousBase : ' + ISNULL( CONVERT( VARCHAR, @v_idSousBase ), 'null' )
			+ ' / @tac_adresse : ' + ISNULL( CONVERT( VARCHAR, @tac_adresse ), 'null' )
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace

	-- =============================================
	-- Compte Rendu de Prise OK 
	-- =============================================
	IF( @v_action = @TAC_ACTION_PRISE and @v_statutPrimaire = @CODE_OK )
	begin
		-- Pas de Traitement sur la Prise

		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
			
		
	
	END
	-- =============================================
	-- Compte Rendu de Prise KO 
	-- =============================================
	ELSE IF( @v_action = @TAC_ACTION_PRISE and @v_statutPrimaire = @CODE_KO )
	BEGIN
		-- Pas de Traitement sur la Fausse Prise

		SET @trace = 'PRISE KO'
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
			
		IF( @v_description = @DESC_ERREUR_ACTIONPRIMAIRE )
		BEGIN
			set @trace = 'ERREUR <> MOUVEMENT'
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'DEBUG',
										@v_trace = @trace
			
			
		END
	END
	-- =============================================
	-- Compte Rendu de Dépose OK 
	-- =============================================
	ELSE IF( @v_action = @TAC_ACTION_DEPOSE and @v_statutPrimaire = @CODE_OK )
	BEGIN
		-- Vérification Adresse Exécution Dépose en Entrée Démaculeuse Magasin = 3 et Coté = 1
		IF EXISTS(	SELECT
						1
					FROM dbo.INT_ADRESSE
					WHERE dbo.INT_ADRESSE.ADR_MAGASIN = 3
					AND dbo.INT_ADRESSE.ADR_COTE = 1
					AND dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSysteme
					AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBase
					AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBase)
		BEGIN
			-- Envoi des Informations à la Démaculeuse	
			IF(@v_description in (@DESC_EXEC_MANU, @DESC_EXEC_AUTO))
			BEGIN
				set @trace = 'DEPOSE OK' 
						+ ' / @tac_adresse : ' + ISNULL( CONVERT( VARCHAR, @tac_adresse ), 'null' )
				SET @trace = @procStock + '/' + @trace
				EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
											@v_log_idlog = 'DEBUG',
											@v_trace = @trace
				-- Récupération de la ligne de démaculage
				SELECT
					@idLigne = dbo.INT_ADRESSE.ADR_COULOIR
				FROM dbo.INT_ADRESSE
				WHERE dbo.INT_ADRESSE.ADR_IDSYSTEME = @v_idSysteme
				AND dbo.INT_ADRESSE.ADR_IDBASE = @v_idBase
				AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = @v_idSousBase

				-- Récupération du sens d'enroulement
				SELECT
					@idSensEnroulement = dbo.SPC_CHG_SENSENROULEMENT.SSE_SENSENROULEMENT
				FROM dbo.INT_CHARGE_VIVANTE
				JOIN dbo.SPC_CHG_SENSENROULEMENT
					ON dbo.SPC_CHG_SENSENROULEMENT.SSE_ORIENTATION = dbo.INT_CHARGE_VIVANTE.CHG_ORIENTATION
				WHERE dbo.INT_CHARGE_VIVANTE.CHG_IDCHARGE = @v_idCharge
				
				EXEC @retour = dbo.SPC_DMC_DEPOSERBOBINE	@v_idLigne = @idLigne,
															@v_sensEnroulement = @idSensEnroulement,
															@v_idbobine = @v_idCharge
				IF (@retour <> @CODE_OK) 
				BEGIN
					SET @trace = 'SPC_DMC_DEPOSERBOBINE ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'ERREUR',
												@v_trace = @trace
				END
				ELSE
				BEGIN
					SET @trace = 'Bobine Déposée sur la Démaculeuse'
					SET @trace = @procStock + '/' + @trace
					EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
												@v_log_idlog = 'DEBUG',
												@v_trace = @trace
				END
				
			END
		END
		------------------------------------------
		--Traitement specifique AFFAIRE pour Dépose OK
		------------------------------------------
		
	END
	-- =============================================
	-- Compte Rendu de Dépose KO 
	-- =============================================
	ELSE IF( @v_action = @TAC_ACTION_DEPOSE and @v_statutPrimaire = @CODE_KO and @v_description = @DESC_ERREUR_ACTIONPRIMAIRE )
	BEGIN			
		EXEC @retour = dbo.INT_RESTARTMISSION @v_mis_idmission = @v_idMission
		IF(@retour <> @CODE_OK)
		begin
			SET @trace = 'INT_RESTARTMISSION : ' + ISNULL( CONVERT( varchar, @retour ), 'null' )
						+ ' / @v_mis_idmission : ' + ISNULL( CONVERT( varchar, @v_idMission ), 'null' )
			SET @trace = @procStock + '/' + @trace
			EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
										@v_log_idlog = 'ERREUR',
										@v_trace = @trace
		end
		
		------------------------------------------
		--Traitement specifique AFFAIRE pour Fausse Dépose
		------------------------------------------
	end
END
END
END

