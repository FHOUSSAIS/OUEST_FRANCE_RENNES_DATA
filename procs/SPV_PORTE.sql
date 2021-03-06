SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_PORTE
-- Paramètre d'entrée	: @v_action : Action à mener
--							0 : Contrôle des ouvertures
--							1 : Ouverture
--							2 : Fermeture
--							3 : Contrôle des fermetures
--                          4 : Liste les AGV pour demande de relance :
--                              - apres reprise de com
--                              - apres re-ouverture de porte
--                          5 : reset de l'info motif d'arret dans INFO_AGV
--						  @v_por_id : Identifiant porte
--						  @v_agv : Identifiant AGV :
--                          !!!! un seul agv dans la liste sauf pour l'action 5 !!!!
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--				@CODE_KO_INCORRECT : Configuration incorrecte
-- Descriptif		: Gestion des portes
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_PORTE]
	@v_action smallint = 0,
	@v_por_id int = NULL,
	@v_agv varchar(400) = NULL
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
	@v_por_etat bit,
	@v_por_service bit,
	@v_por_commande tinyint,
	@v_por_commande_ouverture int,
	@v_por_valeur_ouverture bit,
	@v_int_type tinyint,
	@v_sas_id int,
	@v_sql varchar(400)

DECLARE	@v_iag_idTable table (IAG_ID tinyint, INT_ETAT int, IAG_MOTIFARRETDISTANCE tinyint, AIP_PORTE int)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'action
DECLARE
	@ACTI_CONTROLE_OUVERTURE_PORTE tinyint,
	@ACTI_OUVERTURE_PORTE tinyint,
	@ACTI_FERMETURE_PORTE tinyint,
	@ACTI_CONTROLE_FERMETURE_PORTE tinyint,
	@ACTI_AGV_SOUS_PORTE_ARRET tinyint,
	@ACTI_AGV_SOUS_PORTE_RELANCE tinyint,
	@ACTI_RESET_MOTIF_ARRET tinyint
	
-- Déclaration des constantes de type d'interface
DECLARE
	@TYPE_ENTREE_SORTIE tinyint,
	@TYPE_VARIABLE_AUTOMATE tinyint

-- Déclaration des motifs d'arret a distance
DECLARE
	@MOTIF_ARRET_NONE tinyint,
	@MOTIF_ARRET_FERMETURE_PORTE tinyint,
	@MOTIF_ARRET_PERTE_COM tinyint
	
-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET	@ACTI_CONTROLE_OUVERTURE_PORTE = 0
	SET @ACTI_OUVERTURE_PORTE = 1
	SET @ACTI_FERMETURE_PORTE = 2
	SET @ACTI_CONTROLE_FERMETURE_PORTE = 3
	SET @ACTI_AGV_SOUS_PORTE_RELANCE = 4
	SET @ACTI_RESET_MOTIF_ARRET = 5
	SET @TYPE_ENTREE_SORTIE = 1
	SET @TYPE_VARIABLE_AUTOMATE = 5
	SET @MOTIF_ARRET_NONE = 0
	SET @MOTIF_ARRET_FERMETURE_PORTE = 2
	SET @MOTIF_ARRET_PERTE_COM = 3
	
-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO	
	IF @v_agv = ''
		SET @v_agv = NULL

	IF @v_action IN (@ACTI_OUVERTURE_PORTE, @ACTI_FERMETURE_PORTE)
	BEGIN
		SELECT @v_por_etat = POR_ETAT, @v_por_commande = POR_COMMANDE, @v_por_service = POR_SERVICE,
			@v_int_type = INT_TYPE_LOG,
			@v_por_commande_ouverture = CASE INT_TYPE_LOG
										 WHEN @TYPE_ENTREE_SORTIE THEN POR_ENTREE_SORTIE_COMMANDE
										 WHEN @TYPE_VARIABLE_AUTOMATE THEN POR_VARIABLE_AUTOMATE_COMMANDE
										 ELSE NULL END,
			@v_por_valeur_ouverture = POR_VALEUR_OUVERTURE FROM PORTE
			LEFT OUTER JOIN INTERFACE ON INT_ID_LOG = POR_INTERFACE WHERE POR_ID = @v_por_id
		IF @v_por_commande_ouverture IS NOT NULL AND @v_por_valeur_ouverture IS NOT NULL
		BEGIN
			IF @v_por_service = 1
			BEGIN
				SELECT @v_sas_id = A.APS_SAS FROM ASSOCIATION_PORTE_SAS A WHERE A.APS_PORTE = @v_por_id
					AND EXISTS (SELECT 1 FROM ASSOCIATION_PORTE_SAS B INNER JOIN PORTE ON POR_ID = B.APS_PORTE
					WHERE B.APS_SAS = A.APS_SAS AND B.APS_PORTE <> @v_por_id AND POR_SERVICE = 1)			
				-- Demande d'ouverture
				--	Sans sas :
				--		- Porte fermée sans commande ou porte ouverte avec commande de fermeture
				--	Avec sas :
				--		- Porte1 fermée sans commande ou porte1 ouverte avec commande de fermeture
				--		- Porte2 fermée sans commande
				--		- Pas d'AGV dans le sas
				-- Demande de fermeture
				--	Sans sas :
				--		- Porte ouverte sans commande ou porte fermée avec commande d'ouverture
				--		- Pas d'AGV sous la porte
				--	Avec sas :
				--		- Porte1 ouverte sans commande ou porte1 fermée avec commande d'ouverture
				IF ((@v_action = @ACTI_OUVERTURE_PORTE AND ((@v_por_etat = 0 AND ((@v_por_commande IS NULL) OR (@v_por_commande = 0))) OR (@v_por_etat = 1 AND @v_por_commande = 0))
					AND ((@v_sas_id IS NULL) OR (@v_sas_id IS NOT NULL AND EXISTS (SELECT 1 FROM ASSOCIATION_PORTE_SAS INNER JOIN PORTE ON POR_ID = APS_PORTE WHERE APS_SAS = @v_sas_id AND APS_PORTE <> @v_por_id AND POR_ETAT = 0 AND POR_COMMANDE IS NULL)
					AND NOT EXISTS (SELECT 1 FROM ASSOCIATION_INFO_AGV_PORTE INNER JOIN ASSOCIATION_PORTE_SAS ON APS_PORTE = AIP_PORTE WHERE APS_SAS = @v_sas_id AND AIP_INFO_AGV <> @v_agv AND ((AIP_AUTORISATION = 1) OR (AIP_AUTORISATION = 0 AND AIP_INDEX = 0))))))
					OR (@v_action = @ACTI_FERMETURE_PORTE AND ((@v_por_etat = 1 AND ((@v_por_commande IS NULL) OR (@v_por_commande = 1))) OR (@v_por_etat = 0 AND @v_por_commande = 1))
					AND ((@v_sas_id IS NULL AND NOT EXISTS (SELECT 1 FROM ASSOCIATION_INFO_AGV_PORTE WHERE AIP_PORTE = @v_por_id)) OR (@v_sas_id IS NOT NULL))))
				BEGIN
					IF @v_action = @ACTI_FERMETURE_PORTE
						SET @v_por_valeur_ouverture = ~@v_por_valeur_ouverture
					IF @v_int_type = @TYPE_ENTREE_SORTIE
						EXEC @v_status = INT_SETENTREESORTIE @v_por_commande_ouverture, @v_por_valeur_ouverture
					ELSE
						EXEC @v_status = INT_SETVARIABLEAUTOMATE @v_por_commande_ouverture, @v_por_valeur_ouverture
					SET @v_error = @@ERROR
					IF @v_status = @CODE_OK AND @v_error = 0
						SET @v_retour = @CODE_OK
					ELSE
						SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
				END
				ELSE
					SET @v_retour = @CODE_OK
			END
			ELSE
				SET @v_retour = @CODE_OK
		END
		ELSE
			SET @v_retour = @CODE_KO_INCORRECT
	END
	ELSE IF @v_action = @ACTI_CONTROLE_OUVERTURE_PORTE
	BEGIN
		INSERT INTO @v_iag_idTable (IAG_ID, INT_ETAT)
			SELECT IAG_ID, MAX(INT_ETAT) FROM INFO_AGV
			    INNER JOIN ASSOCIATION_INFO_AGV_PORTE ON AIP_INFO_AGV = IAG_ID
			    INNER JOIN PORTE ON POR_ID = AIP_PORTE
			    INNER JOIN INT_INTERFACE ON INT_IDINTERFACE = POR_INTERFACE
				WHERE IAG_OPERATIONNEL = 'O' AND IAG_ARRETDISTANCE = 0
				      AND IAG_MOTIFARRETDISTANCE = @MOTIF_ARRET_NONE
				      AND AIP_AUTORISATION = 1 AND POR_SERVICE = 1
				      AND NOT (POR_ETAT = 1 AND POR_COMMANDE IS NULL)
				GROUP BY IAG_ID
        
        UPDATE INFO_AGV
            SET IAG_MOTIFARRETDISTANCE = CASE WHEN INT_ETAT = 1 THEN @MOTIF_ARRET_FERMETURE_PORTE ELSE @MOTIF_ARRET_PERTE_COM END
			FROM @v_iag_idTable A
			WHERE INFO_AGV.IAG_ID = A.IAG_ID
        
        SELECT IAG_ID FROM @v_iag_idTable
	END
	ELSE IF @v_action = @ACTI_CONTROLE_FERMETURE_PORTE
	BEGIN
		DECLARE c_porte CURSOR LOCAL FAST_FORWARD FOR SELECT AIP_PORTE FROM ASSOCIATION_INFO_AGV_PORTE WHERE AIP_INFO_AGV = @v_agv
		OPEN c_porte
		FETCH NEXT FROM c_porte INTO @v_por_id
		WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
		BEGIN
			DELETE ASSOCIATION_INFO_AGV_PORTE WHERE AIP_INFO_AGV = @v_agv AND AIP_PORTE = @v_por_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_status = SPV_PORTE @v_action = @ACTI_FERMETURE_PORTE, @v_por_id = @v_por_id
				SET @v_error = @@ERROR
			END
			FETCH NEXT FROM c_porte INTO @v_por_id
		END
		CLOSE c_porte
		DEALLOCATE c_porte
		IF @v_status = @CODE_OK AND @v_error = 0
			SET @v_retour = @CODE_OK
		ELSE
			SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END	
	END
	ELSE IF @v_action = @ACTI_AGV_SOUS_PORTE_RELANCE
	BEGIN

		INSERT INTO @v_iag_idTable (IAG_ID, IAG_MOTIFARRETDISTANCE, AIP_PORTE)
			SELECT IAG_ID, IAG_MOTIFARRETDISTANCE, AIP_PORTE FROM INFO_AGV
			    INNER JOIN ASSOCIATION_INFO_AGV_PORTE ON AIP_INFO_AGV = IAG_ID
			    INNER JOIN PORTE ON POR_ID = AIP_PORTE
				WHERE IAG_OPERATIONNEL = 'O'
				      AND IAG_MOTIFARRETDISTANCE IN ( @MOTIF_ARRET_PERTE_COM, @MOTIF_ARRET_FERMETURE_PORTE )
				      AND AIP_AUTORISATION = 1 AND POR_SERVICE = 1
				      AND POR_ETAT = 1 AND POR_COMMANDE IS NULL
		
		SELECT IAG_ID, IAG_MOTIFARRETDISTANCE, AIP_PORTE FROM @v_iag_idTable
        
   	END
	ELSE IF @v_action = @ACTI_RESET_MOTIF_ARRET
	BEGIN

        SET @v_sql = 'UPDATE INFO_AGV SET IAG_MOTIFARRETDISTANCE ='  + CONVERT(varchar(10),@MOTIF_ARRET_NONE)
                     + 'WHERE IAG_ID IN (' + @v_agv + ')'
		EXEC (@v_sql)
		SET @v_error = @@ERROR

	    IF @v_error = 0
		    SET @v_retour = @CODE_OK
	    ELSE
		    SET @v_retour = @CODE_KO_SQL
	END

	RETURN @v_retour

