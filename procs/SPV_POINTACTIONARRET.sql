SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_POINTACTIONARRET
-- Paramètre d'entrée	: @v_type : Type
--						    0 : Spécifique
--						    1 : Standard
--						  @v_iag_idagv : Identifiant AGV
--						  @v_idpoint : Identifiant point action
--						  @v_idaction : Identifiant action
--						  @v_idcondition : Identifiant condition
--						  @v_paramAction : Paramètre action
--						  @v_paramArret : Paramètre arret
--						  @v_destinataire : destinataire du point action (SPV=2/AGV=0)
--						  @v_tra_idtraduction : traduction liée au point action
--                                              (si point action à destination de l'AGV)
--						  @v_validation : si point action à destination de l'AGV 
--                                        0->detection 1->validation
--						  @v_cyclique : true si evaluation cyclique, false sinon
-- Paramètre de sortie	: @v_valeur : Résultat de l'évaluation de la condition
--			  Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_INCONNU : Action inconnue
--			    @CODE_KO_PARAM : Absence procédure stockée de condition spécifique
--				@CODE_KO_INCORRECT : Configuration incorrecte
--				@CODE_KO_SQL : Erreur SQL
--			    @CODE_KO_SPECIFIQUE : Refus spécifique
-- Descriptif		: Evaluation de la condition liée aux points actions avec arrêt
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_POINTACTIONARRET]
	@v_type bit,
	@v_iag_idagv tinyint,
	@v_idpoint int,
	@v_idaction int,
	@v_idcondition int,	
	@v_paramAction varchar(8000),
	@v_paramArret varchar(8000),
	@v_destinataire int = 2,
	@v_tra_idtraduction int = Null,
	@v_validation bit = 0,
	@v_cyclique bit = 0,
	@v_valeur int = 0 out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_par_valeur varchar(128),
	@v_por_id int,
	@v_por_etat bit,
	@v_por_service bit,
	@v_por_commande tinyint,
	@v_por_commande_ouverture int,
	@v_por_valeur_ouverture bit,
	@v_sas_id int
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_PARAM tinyint,
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_SPECIFIQUE tinyint

-- Déclaration des constantes d'action
DECLARE
	@ACTI_OUVERTURE_PORTE tinyint,
	@ACTI_FERMETURE_PORTE tinyint
	
-- Déclaration des destinataires du PointAction
DECLARE
	@DESTI_SPV tinyint
	
-- Déclaration des constantes de type d'interface
DECLARE
	@TYPE_ENTREE_SORTIE tinyint,
	@TYPE_VARIABLE_AUTOMATE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_PARAM = 8
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_SPECIFIQUE = 20
	SET @ACTI_OUVERTURE_PORTE = 1
	SET @ACTI_FERMETURE_PORTE = 2
	SET @TYPE_ENTREE_SORTIE = 1
	SET @TYPE_VARIABLE_AUTOMATE = 5
	SET @DESTI_SPV = 2

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_OK
	IF( @v_validation = 0)
		SET @v_valeur = 0
	ELSE
		SET @v_valeur = 1

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	IF @v_destinataire = @DESTI_SPV AND @v_cyclique = 0
	BEGIN
		BEGIN TRAN
		UPDATE INFO_AGV SET IAG_IDPOINTARRET = @v_idpoint
			WHERE IAG_ID = @v_iag_idagv AND IAG_IDPOINTARRET <> @v_idpoint
		
		SET @v_error = @@ERROR
		IF @v_error <> 0
			SET @v_retour = @CODE_KO_SQL
		
		IF @v_error = 0
			COMMIT TRAN
		ELSE
			ROLLBACK TRAN
	END

	-- on verifie si l'evaluation est toujours necessaire
	IF @v_cyclique = 0
	   OR EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND IAG_IDPOINTARRET = @v_idpoint)
	BEGIN
		BEGIN TRAN
	
		IF @v_destinataire = @DESTI_SPV
		BEGIN
			IF @v_type = 1
			BEGIN
			
				-- appel a la partie PointAction seulement une fois
				IF @v_cyclique = 0
					EXEC @v_retour = SPV_POINTACTION @v_iag_idagv = @v_iag_idagv, @v_idaction = @v_idaction, @v_parametre = @v_paramAction
			
				IF @v_retour = @CODE_OK
				BEGIN
					IF @v_idcondition = @ACTI_OUVERTURE_PORTE
					BEGIN
						SELECT @v_por_id = POR_ID, @v_por_etat = POR_ETAT, @v_por_commande = POR_COMMANDE, @v_por_service = POR_SERVICE,
							@v_por_commande_ouverture = CASE INT_TYPE_LOG
															WHEN @TYPE_ENTREE_SORTIE THEN POR_ENTREE_SORTIE_COMMANDE
															WHEN @TYPE_VARIABLE_AUTOMATE THEN POR_VARIABLE_AUTOMATE_COMMANDE
															ELSE NULL END,
							@v_por_valeur_ouverture = POR_VALEUR_OUVERTURE FROM PORTE
							LEFT OUTER JOIN INTERFACE ON INT_ID_LOG = POR_INTERFACE WHERE POR_ID = @v_paramArret
						IF @v_por_id IS NOT NULL AND @v_por_commande_ouverture IS NOT NULL AND @v_por_valeur_ouverture IS NOT NULL
						BEGIN
							SET @v_tra_idtraduction = 1897
							IF @v_por_service = 0
							BEGIN
								SET @v_valeur = 1
								SET @v_retour = @CODE_OK
							END
							ELSE IF @v_por_etat = 1 AND @v_por_commande IS NULL
							BEGIN
								SELECT @v_sas_id = A.APS_SAS FROM ASSOCIATION_PORTE_SAS A WHERE A.APS_PORTE = @v_por_id
									AND EXISTS (SELECT 1 FROM ASSOCIATION_PORTE_SAS B INNER JOIN PORTE ON POR_ID = B.APS_PORTE
									WHERE B.APS_SAS = A.APS_SAS AND B.APS_PORTE <> @v_por_id AND POR_SERVICE = 1)
								IF ((@v_sas_id IS NULL) OR (@v_sas_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ASSOCIATION_INFO_AGV_PORTE INNER JOIN ASSOCIATION_PORTE_SAS ON APS_PORTE = AIP_PORTE
									WHERE APS_SAS = @v_sas_id AND AIP_INFO_AGV <> @v_iag_idagv AND ((AIP_AUTORISATION = 1) OR (AIP_AUTORISATION = 0 AND AIP_INDEX = 0)))
									AND NOT EXISTS (SELECT 1 FROM ASSOCIATION_INFO_AGV_PORTE WHERE AIP_PORTE = @v_por_id AND AIP_INFO_AGV <> @v_iag_idagv
									AND AIP_ORDRE < (SELECT AIP_ORDRE FROM ASSOCIATION_INFO_AGV_PORTE WHERE AIP_PORTE = @v_por_id AND AIP_INFO_AGV = @v_iag_idagv))))
								BEGIN
									SET @v_valeur = 1
									SET @v_retour = @CODE_OK
								END
								ELSE
									SET @v_retour = @CODE_OK
							END
							ELSE
								SET @v_retour = @CODE_OK
							IF @v_valeur = 1
							BEGIN
								UPDATE ASSOCIATION_INFO_AGV_PORTE SET AIP_AUTORISATION = 1 WHERE AIP_INFO_AGV = @v_iag_idagv AND AIP_PORTE = @v_por_id
								SET @v_error = @@ERROR
								IF @v_error <> 0
									SET @v_retour = @CODE_KO_SQL
							END
							ELSE
							BEGIN
								EXEC @v_status = SPV_PORTE @v_action = @ACTI_OUVERTURE_PORTE, @v_por_id = @v_por_id, @v_agv = @v_iag_idagv
								SET @v_error = @@ERROR
								IF @v_status = @CODE_OK AND @v_error = 0
									SET @v_retour = @CODE_OK
								ELSE
									SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
							END
						END
						ELSE
							SET @v_retour = @CODE_KO_INCORRECT
					END
					ELSE
						SET @v_retour = @CODE_KO_INCONNU
				END
			END
			ELSE
			BEGIN
				-- Récupération de la procédure stockée de traitement spécifique
				SELECT @v_par_valeur = CASE PAR_VAL WHEN '' THEN NULL ELSE PAR_VAL END FROM PARAMETRE WHERE PAR_NOM = 'POINTACTIONARRET'
				IF (@v_par_valeur IS NOT NULL)
				BEGIN
					EXEC @v_status = @v_par_valeur @v_iag_idagv, @v_idpoint, @v_idaction, @v_idcondition, @v_paramArret,
						@v_valeur out, @v_tra_idtraduction out
					SET @v_error = @@ERROR
					IF @v_status = @CODE_OK AND @v_error = 0
						SET @v_retour = @CODE_OK
					ELSE
						SET @v_retour = @CODE_KO_SPECIFIQUE		
				END
				ELSE
					SET @v_retour = @CODE_KO_PARAM
			END
		END

		IF @v_valeur = 0
		BEGIN
			UPDATE INFO_AGV SET IAG_POINTARRET = @v_tra_idtraduction WHERE IAG_ID = @v_iag_idagv
			SET @v_error = @@ERROR
			IF @v_error <> 0 AND @v_retour = @CODE_OK
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE IF @v_valeur = 1
		BEGIN
			UPDATE INFO_AGV SET IAG_IDPOINTARRET = 0, IAG_POINTARRET = NULL WHERE IAG_ID = @v_iag_idagv
			SET @v_error = @@ERROR
			IF @v_error <> 0 AND @v_retour = @CODE_OK
				SET @v_retour = @CODE_KO_SQL
		END

		IF @v_error = 0 AND @v_retour = @CODE_OK
			COMMIT TRAN
		ELSE
			ROLLBACK TRAN
	END

	RETURN @v_retour

