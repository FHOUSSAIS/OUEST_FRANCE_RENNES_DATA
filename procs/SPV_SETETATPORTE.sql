SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETETATPORTE
-- Paramètre d'entrée	: 
--				@v_idPorte : identifiant de la porte
-- Paramètres de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_INCONNU : Critère de mission inconnu
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Evaluation des critères de missions calculés
-----------------------------------------------------------------------------------------


CREATE PROCEDURE [dbo].[SPV_SETETATPORTE]
	@v_idPorte int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END


-- Déclaration des constantes de retour
DECLARE
	@CODE_OK int = 0,
	@CODE_KO int = 1
	
-- Déclaration des variables
DECLARE
	@v_error int = 0,
	@v_retour int = @CODE_KO,
	@v_local bit,
	@v_transaction varchar(32) = 'SPV_SETETATPORTE'


	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END

	UPDATE PORTE
	SET POR_ETAT = PORTE_INFO.POR_ETAT,
		POR_COMMANDE =
		(CASE INT_TYPE_LOG
			WHEN 1 THEN
				CASE WHEN
					(SELECT 1 FROM INT_ENTREE_SORTIE
						WHERE PORTE_INFO.POR_ENTREE_SORTIE_COMMANDE = ESL_IDENTREESORTIE
							  AND ESL_QUALITE = 1
							  AND ESL_ETAT = PORTE_INFO.POR_VALEUR_OUVERTURE) = 1
					 AND PORTE_INFO.POR_ETAT = 0
					THEN 1
				ELSE CASE WHEN
                    (SELECT 1 FROM INT_ENTREE_SORTIE
                        WHERE PORTE_INFO.POR_ENTREE_SORTIE_COMMANDE = ESL_IDENTREESORTIE
							  AND ESL_QUALITE = 1
							  AND ESL_ETAT = ~ PORTE_INFO.POR_VALEUR_OUVERTURE) = 1
                    AND PORTE_INFO.POR_ETAT = 1
                    THEN 0
                    ELSE NULL END END
            WHEN 5 THEN
				CASE WHEN
					(SELECT 1 FROM INT_VARIABLE_AUTOMATE
                        WHERE PORTE_INFO.POR_VARIABLE_AUTOMATE_COMMANDE = VAU_IDVARIABLEAUTOMATE
							  AND VAU_QUALITE = 1
							  AND VAU_VALEUR = PORTE_INFO.POR_VALEUR_OUVERTURE) = 1
                     AND PORTE_INFO.POR_ETAT = 0
                     THEN 1
                ELSE CASE WHEN
                    (SELECT 1 FROM INT_VARIABLE_AUTOMATE
                        WHERE PORTE_INFO.POR_VARIABLE_AUTOMATE_COMMANDE = VAU_IDVARIABLEAUTOMATE
							  AND VAU_QUALITE = 1
							  AND VAU_VALEUR = ~ PORTE_INFO.POR_VALEUR_OUVERTURE) = 1
                     AND PORTE_INFO.POR_ETAT = 1
                     THEN 0
                ELSE NULL END END END)
		
	FROM (SELECT PORTE_1.POR_ID AS POR_ID,
			(CASE INT_TYPE_LOG
			   WHEN 1 THEN
					CASE WHEN
						(SELECT 1 FROM INT_ENTREE_SORTIE
							WHERE POR_ENTREE_SORTIE_ETAT = ESL_IDENTREESORTIE
								  AND ESL_QUALITE = 1
								  AND ESL_ETAT = POR_VALEUR_OUVERT) = 1 AND
						(SELECT 1 FROM INT_ENTREE_SORTIE
							WHERE POR_ENTREE_SORTIE_COMMANDE = ESL_IDENTREESORTIE AND ESL_WRITE = 0) = 1
						 THEN 1
					ELSE 0 END
			   WHEN 5 THEN
					CASE WHEN
						(SELECT 1 FROM INT_VARIABLE_AUTOMATE
							WHERE POR_VARIABLE_AUTOMATE_ETAT = VAU_IDVARIABLEAUTOMATE
								  AND VAU_QUALITE = 1
								  AND VAU_VALEUR = POR_VALEUR_OUVERT) = 1 AND
						(SELECT 1 FROM INT_VARIABLE_AUTOMATE
							WHERE POR_VARIABLE_AUTOMATE_COMMANDE = VAU_IDVARIABLEAUTOMATE AND VAU_WRITE = 0) = 1
						 THEN 1
					ELSE 0 END
			   ELSE NULL END) AS POR_ETAT,
			   dbo.INTERFACE.INT_TYPE_LOG,
			   PORTE_1.POR_ENTREE_SORTIE_COMMANDE,
			   PORTE_1.POR_VARIABLE_AUTOMATE_COMMANDE, 
               PORTE_1.POR_VALEUR_OUVERTURE
		FROM PORTE AS PORTE_1
		LEFT OUTER JOIN dbo.INTERFACE ON dbo.INTERFACE.INT_ID_LOG = PORTE_1.POR_INTERFACE
		WHERE PORTE_1.POR_ID = @v_idPorte
		) AS PORTE_INFO WHERE PORTE_INFO.POR_ID = PORTE.POR_ID


	SET @v_error = @@ERROR
	IF @v_error = 0
		SET @v_retour = @CODE_OK
	
	IF @v_local = 1
	BEGIN
		IF @v_retour = @CODE_OK
			COMMIT TRAN @v_transaction
		ELSE
			ROLLBACK TRAN @v_transaction
	END

	RETURN @v_retour


