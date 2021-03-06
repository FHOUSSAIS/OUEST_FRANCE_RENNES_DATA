SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_INTERFACE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_vue_ordre : Ordre d'affichage
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
--			  @v_spe_dll : Dll
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_vue_id : Identifiant vue
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des interfaces
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_INTERFACE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_int_id_log int out,
	@v_int_id_phys int out,
	@v_int_type_log tinyint,
	@v_int_type_phys tinyint,
	@v_int_actif bit,
	@v_ipi_portspv smallint,
	@v_ipi_procspv int,
	@v_ipi_portpil smallint,
	@v_ipi_host_pil varchar(50),
	@v_ipi_procpil int,
	@v_iri_capacite smallint,
	@v_iao_topic varchar(50),
	@v_iao_refresh int,
	@v_iao_serveur varchar(8000),
	@v_iao_machine varchar(256),
	@v_iao_separateur varchar(1),
	@v_ieo_topic varchar(50),
	@v_ieo_refresh int,
	@v_ieo_serveur varchar(8000),
	@v_ieo_machine varchar(256),
	@v_ieo_separateur varchar(1),
	@v_ios_port int,
	@v_iht_intervalle int,
	@v_ifa_distantreception varchar(2000),
	@v_ifa_distantemission varchar(2000),
	@v_ifa_localreception varchar(2000),
	@v_ifa_localemission varchar(2000),
	@v_ifa_masque varchar(16),
	@v_bdd_serveur_lie varchar(256),
	@v_bdd_frequence int,
	@v_bdd_table_locale varchar(256),
	@v_bdd_sens bit,
	@v_bdd_catalogue_dist varchar(256),
	@v_bdd_schema_dist varchar(256),
	@v_bdd_table_dist varchar(256),
	@v_socket_type bit,
	@v_socket_port int,
	@v_socket_client_ip varchar(256),
	@v_socket_client_host varchar(256),
	@v_socket_cnx_id int,
	@v_socket_srv_client_lbl varchar(8000),
	@v_socket_srv_client_ip varchar(256),
	@v_socket_srv_client_host varchar(256),
	@v_tra_id int out,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int,
	@v_max int,
	@v_old_socket_type bit,
	@v_tra_id2 int,
	@v_id int,
	@v_vyt_id int,
	@v_vyt_sql varchar(8000),
	@v_ordre tinyint,
	@v_retourTmp smallint,
	@v_lib_tmp varchar(8000),
	@ACTION_INSERT int = 0,
	@ACTION_UPDATE int = 1,
	@ACTION_DELETE int = 2,
	@SSACT_UPDATE_ACTIF int = 0,
	@SSACT_UPDATE_ITF int = 1,
	@SSACT_UPDATE_LIBELLE int = 2,
	@SSACT_UPDATE_PART_ITF int = 3,
	@TYPE_TC int = 100,
	@TYPE_BDD int = 101,
	@TYPE_AUTOMATE int = 104,
	@TYPE_ES int = 105,
	@TYPE_HORLOGE int = 107,
	@TYPE_FICHIER int = 108,
	@TYPE_SOCKET int = 109,
	@RETOUR_TOPIC_EXISTS int = 3306,
	@ROUGE int = 255,
	@VERT int = 65280
	

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = @ACTION_INSERT
	BEGIN
		IF @v_ssaction = @SSACT_UPDATE_ITF
		BEGIN
			EXEC @v_error = CFG_ABONNE @v_action, NULL, @v_int_id_log out, 0, NULL, NULL, NULL, NULL, NULL, @v_lib_libelle, @v_lan_id, @v_tra_id out, @v_retour out
			IF @v_error = 0
			BEGIN
				SELECT @v_int_id_phys = CASE SIGN(MIN(IPY_ID)) WHEN -1 THEN MIN(IPY_ID) - 1 ELSE -1 END FROM INTERFACE_PHYSIQUE
				INSERT INTO INTERFACE_PHYSIQUE (IPY_ID) VALUES (@v_int_id_phys) 
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					IF @v_int_type_phys = @TYPE_TC
						INSERT INTO INTERFACE_PILOTAGE_UDP (IPI_ID, IPI_PORT_SPV, IPI_IDPROC_SPV, IPI_PORT_PIL, IPI_HOST_PIL, IPI_IDPROC_PIL, IPI_ETAT, IPI_COMPTEUR) VALUES (@v_int_id_phys, 9001, 201, 9000, '127.0.0.1', 101, 0, 0)
					ELSE IF @v_int_type_phys = @TYPE_BDD
						INSERT INTO INTERFACE_BDD_LS (IBL_ID, IBL_SERVEUR_LIE, IBL_FREQUENCE, IBL_ETAT) VALUES(@v_int_id_phys, '', 10, 0)
					ELSE IF @v_int_type_phys = 103
						INSERT INTO INTERFACE_ROUTEUR_IHM (IRI_ID, IRI_CAPACITE) VALUES (@v_int_id_phys, 1000)
					ELSE IF @v_int_type_phys = @TYPE_AUTOMATE
						INSERT INTO INTERFACE_AUTOMATE_OPC (IAO_ID, IAO_TOPIC, IAO_ETAT, IAO_RAFRAICHISSEMENT, IAO_SERVEUR, IAO_SEPARATEUR) VALUES (@v_int_id_phys, '', 0, 1000, 'APPLICOM.OPCServer.1', '.')
					ELSE IF @v_int_type_phys = @TYPE_ES
						INSERT INTO INTERFACE_ES_OPC (IEO_ID, IEO_TOPIC, IEO_ETAT, IEO_RAFRAICHISSEMENT, IEO_SERVEUR, IEO_SEPARATEUR) VALUES (@v_int_id_phys, '', 0, 1000, 'APPLICOM.OPCServer.1', '.')
					ELSE IF @v_int_type_phys = 106
						INSERT INTO INTERFACE_OSYS (IOS_ID, IOS_PORT) VALUES (@v_int_id_phys, 5020)
					ELSE IF @v_int_type_phys = @TYPE_HORLOGE
						INSERT INTO INTERFACE_HORLOGE_THREAD (IHT_ID, IHT_INTERVALLE, IHT_ETAT) VALUES (@v_int_id_phys, 30000, 0)
					ELSE IF @v_int_type_phys = @TYPE_FICHIER
						INSERT INTO INTERFACE_FICHIER_API (IFA_ID, IFA_DISTANT_RECEPTION, IFA_DISTANT_EMISSION, IFA_LOCAL_RECEPTION, IFA_LOCAL_EMISSION, IFA_MASQUE, IFA_ETAT) VALUES (@v_int_id_phys, '\\remotehost\share$\receive', '\\remotehost\share$\send', 'receive', 'send', '*.*', 0)
					ELSE IF @v_int_type_phys = @TYPE_SOCKET
					BEGIN
						INSERT INTO INTERFACE_SOCKET_TCPIP (IST_ID, IST_TYPE, IST_PORT, IST_ETAT, IST_ADDRESS, IST_HOST) VALUES(@v_int_id_phys, 0, 0, 0, NULL, NULL)
						
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							set @v_max = (select ISNULL(MAX(CNX_ID), 0) FROM CONNEXION) + 1
							INSERT INTO CONNEXION (CNX_ID, CNX_TRADUCTION, CNX_INTERFACE, CNX_ADDRESS, CNX_HOST, CNX_ETAT) VALUES(@v_max, NULL, @v_int_id_phys, NULL, NULL, 0)
						END
					END
					
					
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						INSERT INTO INTERFACE (INT_ID_LOG, INT_TYPE_LOG, INT_ACTIF, INT_ID_PHYS, INT_TYPE_PHYS, INT_IDTRADUCTION, INT_SYSTEME)
							VALUES (@v_int_id_log, @v_int_type_log, 1, @v_int_id_phys, @v_int_type_phys, @v_tra_id, 0)
						SET @v_error = @@ERROR
					END
					
					IF @v_error = 0
					BEGIN
						-- insertion d'un voyant
						SET @v_vyt_sql = 'SELECT INT_ETAT FROM INT_INTERFACE WHERE INT_IDINTERFACE=' + CAST( @v_int_id_log AS varchar(8000) )
						SET @v_ordre = (select ISNULL(MAX(VYT_ORDRE), 0) FROM VOYANT) + 1
						EXEC @v_error = CFG_VOYANT @v_action = @ACTION_INSERT,
												   @v_vyt_id = @v_vyt_id out,
												   @v_vyt_ordre = @v_ordre,
												   @v_lan_id = @v_lan_id,
												   @v_lib_libelle = @v_lib_libelle,
												   @v_vyt_sql = @v_vyt_sql,
												   @v_vyt_actif = 1,
												   @v_retour = @v_retourTmp out
						IF @v_error = 0
						BEGIN
							-- modification du voyant
							EXEC @v_error = CFG_VOYANT @v_action = @ACTION_UPDATE,
													   @v_vyt_id = @v_vyt_id out,
													   @v_vyt_ordre = @v_ordre,
													   @v_lan_id = @v_lan_id,
													   @v_lib_libelle = @v_lib_libelle,
													   @v_vyt_sql = @v_vyt_sql,
													   @v_vyt_actif = 1,
													   @v_retour = @v_retourTmp out

							IF @v_error = 0
							BEGIN
								-- ajout couleur rouge
								SELECT @v_lib_tmp = LIB_LIBELLE FROM LIBELLE WHERE LIB_TRADUCTION = 3310 AND LIB_LANGUE = @v_lan_id
								EXEC @v_error = CFG_COULEUR @v_action = @ACTION_INSERT,
															@v_cou_voyant = @v_vyt_id,
															@v_lan_id = @v_lan_id,
															@v_lib_libelle = @v_lib_tmp,
															@v_cou_valeur = 0,
															@v_cou_couleur = @ROUGE,
															@v_retour = @v_retourTmp out
								
								IF @v_error = 0
								BEGIN
									-- ajout couleur vert
									SELECT @v_lib_tmp = LIB_LIBELLE FROM LIBELLE WHERE LIB_TRADUCTION = 3311 AND LIB_LANGUE = @v_lan_id
									EXEC @v_error = CFG_COULEUR @v_action = @ACTION_INSERT,
																@v_cou_voyant = @v_vyt_id,
																@v_lan_id = @v_lan_id,
																@v_lib_libelle = @v_lib_tmp,
																@v_cou_valeur = 1,
																@v_cou_couleur = @VERT,
																@v_retour = @v_retourTmp out

									IF @v_error = 0
										SET @v_retour = 0
								END
							END
						END
					END
				END
			END
		END
		ELSE IF @v_ssaction = @SSACT_UPDATE_PART_ITF
		BEGIN
			select @v_int_type_phys = INT_TYPE_PHYS,
				   @v_int_id_phys = INT_ID_PHYS
				   FROM INTERFACE WHERE INT_ID_LOG = @v_int_id_log
				
			IF @v_int_type_phys = @TYPE_BDD
			BEGIN
				-- ajout d'une table
				INSERT INTO ECHANGE (ECH_TABLE, ECH_INTERFACE, ECH_SENS, ECH_READ, ECH_WRITE, ECH_EVENT) VALUES(@v_bdd_table_locale, @v_int_id_log, @v_bdd_sens, 0, 0, 0)
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					INSERT INTO ECHANGE_LS (ECL_ECHANGE, ECL_INTERFACE, ECL_CATALOGUE, ECL_SCHEMA, ECL_TABLE) VALUES(@v_bdd_table_locale, @v_int_id_phys, @v_bdd_catalogue_dist, @v_bdd_schema_dist, @v_bdd_table_dist)
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
			ELSE IF @v_int_type_phys = @TYPE_SOCKET
			BEGIN
				-- ajout d'un client qui se connectera au seveur
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_socket_srv_client_lbl, @v_tra_id out
				IF @v_error = 0
				BEGIN
					set @v_max = (select ISNULL(MAX(CNX_ID), 0) FROM CONNEXION) + 1
					INSERT INTO CONNEXION (CNX_ID, CNX_TRADUCTION, CNX_INTERFACE, CNX_ADDRESS, CNX_HOST, CNX_ETAT) VALUES(@v_max, @v_tra_id, @v_int_id_phys, @v_socket_srv_client_ip, @v_socket_srv_client_host, 0)
					
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
		END
	END
	ELSE IF @v_action = @ACTION_UPDATE
	BEGIN
		IF @v_ssaction = @SSACT_UPDATE_ACTIF
		BEGIN
			UPDATE INTERFACE SET INT_ACTIF = @v_int_actif WHERE INT_ID_LOG = @v_int_id_log
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = @SSACT_UPDATE_ITF
		BEGIN
			SET @v_retour = 0 -- v_retour peut etre surcharge en dessous
		
			IF @v_int_type_phys = @TYPE_TC
				UPDATE INTERFACE_PILOTAGE_UDP SET IPI_PORT_SPV = @v_ipi_portspv, IPI_IDPROC_SPV = @v_ipi_procspv, IPI_PORT_PIL = @v_ipi_portpil, IPI_HOST_PIL = @v_ipi_host_pil, IPI_IDPROC_PIL = @v_ipi_procpil WHERE IPI_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = @TYPE_BDD
			BEGIN
				UPDATE INTERFACE_BDD_LS SET IBL_SERVEUR_LIE = @v_bdd_serveur_lie, IBL_FREQUENCE = @v_bdd_frequence WHERE IBL_ID = @v_int_id_phys
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE ECHANGE_LS SET ECL_CATALOGUE = @v_bdd_catalogue_dist, ECL_SCHEMA = @v_bdd_schema_dist, ECL_TABLE = @v_bdd_table_dist WHERE ECL_ECHANGE = @v_bdd_table_locale
					SET @v_error = @@ERROR
					IF @v_error = 0
						UPDATE ECHANGE SET ECH_SENS = @v_bdd_sens WHERE ECH_TABLE = @v_bdd_table_locale
				END
			END
			ELSE IF @v_int_type_phys = 103
				UPDATE INTERFACE_ROUTEUR_IHM SET IRI_CAPACITE = @v_iri_capacite WHERE IRI_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = @TYPE_AUTOMATE
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM INTERFACE_AUTOMATE_OPC WHERE IAO_TOPIC = @v_iao_topic AND IAO_SERVEUR = @v_iao_serveur AND IAO_ID <> @v_int_id_phys)
					UPDATE INTERFACE_AUTOMATE_OPC SET IAO_TOPIC = @v_iao_topic, IAO_RAFRAICHISSEMENT = @v_iao_refresh, IAO_SERVEUR = @v_iao_serveur, IAO_MACHINE = @v_iao_machine, IAO_SEPARATEUR = @v_iao_separateur WHERE IAO_ID = @v_int_id_phys
				ELSE
					SET @v_retour = @RETOUR_TOPIC_EXISTS
			END
			ELSE IF @v_int_type_phys = @TYPE_ES
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM INTERFACE_ES_OPC WHERE IEO_TOPIC = @v_ieo_topic AND IEO_SERVEUR = @v_ieo_serveur AND IEO_ID <> @v_int_id_phys)
					UPDATE INTERFACE_ES_OPC SET IEO_TOPIC = @v_ieo_topic, IEO_RAFRAICHISSEMENT = @v_ieo_refresh, IEO_SERVEUR = @v_ieo_serveur, IEO_MACHINE = @v_ieo_machine, IEO_SEPARATEUR = @v_ieo_separateur WHERE IEO_ID = @v_int_id_phys
				ELSE
					SET @v_retour = @RETOUR_TOPIC_EXISTS
			END
			ELSE IF @v_int_type_phys = 106
				UPDATE INTERFACE_OSYS SET IOS_PORT = @v_ios_port WHERE IOS_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = @TYPE_HORLOGE
				UPDATE INTERFACE_HORLOGE_THREAD SET IHT_INTERVALLE = @v_iht_intervalle WHERE IHT_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = @TYPE_FICHIER
				UPDATE INTERFACE_FICHIER_API SET IFA_DISTANT_RECEPTION = @v_ifa_distantreception, IFA_DISTANT_EMISSION = @v_ifa_distantemission, IFA_LOCAL_RECEPTION = @v_ifa_localreception, IFA_LOCAL_EMISSION = @v_ifa_localemission, IFA_MASQUE = @v_ifa_masque WHERE IFA_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = @TYPE_SOCKET
			BEGIN
				SELECT @v_old_socket_type = IST_TYPE
					FROM INTERFACE_SOCKET_TCPIP WHERE IST_ID = @v_int_id_phys;
				
				IF @v_old_socket_type <> @v_socket_type
				BEGIN
					IF @v_old_socket_type = 1 -- serveur -> client
					BEGIN
						-- suppression des libelles
						DECLARE c_trad CURSOR LOCAL
						FOR SELECT CNX_ID, CNX_TRADUCTION FROM CONNEXION WHERE CNX_INTERFACE = @v_int_id_phys AND CNX_TRADUCTION IS NOT NULL
						FOR UPDATE
						OPEN c_trad
						FETCH NEXT FROM c_trad INTO @v_id, @v_tra_id2
						
						WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
						BEGIN
							DELETE CONNEXION WHERE CNX_ID = @v_id
							SET @v_error = @@ERROR
							IF @v_error = 0
								EXEC @v_error = LIB_TRADUCTION @ACTION_DELETE, NULL, NULL, @v_tra_id2 out
							FETCH NEXT FROM c_trad INTO @v_id, @v_tra_id2
						END
						
						CLOSE c_trad
						DEALLOCATE c_trad
						
						IF @v_error = 0
						BEGIN
							-- suppression des connexions
							DELETE CONNEXION WHERE CNX_INTERFACE = @v_int_id_phys;
							
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								-- creation de la connexion 'cliente'
								set @v_max = (select MAX(CNX_ID) FROM CONNEXION) + 1
								INSERT INTO CONNEXION (CNX_ID, CNX_TRADUCTION, CNX_INTERFACE, CNX_ADDRESS, CNX_HOST, CNX_ETAT) VALUES(@v_max, NULL, @v_int_id_phys, NULL, NULL, 0)
							END
						END
					END
					ELSE -- client -> serveur
						DELETE CONNEXION WHERE CNX_INTERFACE = @v_int_id_phys;
				END
				ELSE IF @v_socket_type = 1 -- on reste en mode serveur
				BEGIN
					UPDATE CONNEXION
						SET CNX_ADDRESS = CASE @v_socket_type WHEN 1 THEN @v_socket_srv_client_ip ELSE NULL END,
							CNX_HOST = CASE @v_socket_type WHEN 1 THEN @v_socket_srv_client_host ELSE NULL END
						WHERE CNX_ID = @v_socket_cnx_id;
					
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						UPDATE LIBELLE
							SET LIB_LIBELLE = @v_socket_srv_client_lbl
							WHERE LIB_LANGUE = @v_lan_id
								AND LIB_TRADUCTION = (select CNX_TRADUCTION FROM CONNEXION WHERE CNX_ID = @v_socket_cnx_id);
					END
				END
				
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE INTERFACE_SOCKET_TCPIP
						SET IST_TYPE = @v_socket_type,
							IST_ADDRESS = CASE @v_socket_type WHEN 1 THEN NULL ELSE @v_socket_client_ip END,
							IST_HOST = CASE @v_socket_type WHEN 1 THEN NULL ELSE @v_socket_client_host END,
							IST_PORT = @v_socket_port
						WHERE IST_ID = @v_int_id_phys;
				END
			END
			
			
			SET @v_error = @@ERROR
			IF @v_error <> 0
				SET @v_retour = 113
		END
		ELSE IF @v_ssaction = @SSACT_UPDATE_LIBELLE
		BEGIN
			-- modification du libelle
			UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle
				   WHERE LIB_LANGUE = @v_lan_id
				   AND LIB_TRADUCTION = (select INT_IDTRADUCTION FROM INTERFACE WHERE INT_ID_PHYS = @v_int_id_phys);
			
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
	END
	ELSE IF @v_action = @ACTION_DELETE
	BEGIN
		select @v_tra_id = INT_IDTRADUCTION,
			   @v_int_type_phys = INT_TYPE_PHYS,
			   @v_int_id_phys = INT_ID_PHYS
			   FROM INTERFACE WHERE INT_ID_LOG = @v_int_id_log
		
		IF @v_ssaction = @SSACT_UPDATE_ITF
		BEGIN
			IF @v_int_type_phys = @TYPE_TC
				DELETE INTERFACE_PILOTAGE_UDP WHERE IPI_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = 103
				DELETE INTERFACE_ROUTEUR_IHM WHERE IRI_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = @TYPE_AUTOMATE
			BEGIN
				DECLARE c_trad CURSOR LOCAL
					FOR SELECT VAU_ID, VAU_IDTRADUCTION FROM VARIABLE_AUTOMATE WHERE VAU_IDINTERFACE = @v_int_id_log
					FOR UPDATE
				OPEN c_trad
				FETCH NEXT FROM c_trad INTO @v_id, @v_tra_id2
				
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					DELETE VARIABLE_AUTOMATE_OPC WHERE VAO_ID = @v_id
					
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE VARIABLE_AUTOMATE WHERE VAU_ID = @v_id
						
						SET @v_error = @@ERROR
						IF @v_error = 0
							EXEC @v_error = LIB_TRADUCTION @ACTION_DELETE, NULL, NULL, @v_tra_id2 out
					END
					FETCH NEXT FROM c_trad INTO @v_id, @v_tra_id2
				END
				
				CLOSE c_trad
				DEALLOCATE c_trad

				
				DELETE INTERFACE_AUTOMATE_OPC WHERE IAO_ID = @v_int_id_phys
			END
			ELSE IF @v_int_type_phys = @TYPE_ES
			BEGIN
				DECLARE c_trad CURSOR LOCAL
					FOR SELECT ESL_ID, ESL_IDTRADUCTION FROM ENTREE_SORTIE WHERE ESL_INTERFACE = @v_int_id_log
					FOR UPDATE
				OPEN c_trad
				FETCH NEXT FROM c_trad INTO @v_id, @v_tra_id2
				
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					DELETE ENTREE_SORTIE_OPC WHERE ESP_ID = @v_id
					
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE ENTREE_SORTIE WHERE ESL_ID = @v_id
						
						SET @v_error = @@ERROR
						IF @v_error = 0
							EXEC @v_error = LIB_TRADUCTION @ACTION_DELETE, NULL, NULL, @v_tra_id2 out
					END
					FETCH NEXT FROM c_trad INTO @v_id, @v_tra_id2
				END
				
				CLOSE c_trad
				DEALLOCATE c_trad
				
				DELETE INTERFACE_ES_OPC WHERE IEO_ID = @v_int_id_phys
			END
			ELSE IF @v_int_type_phys = 106
				DELETE INTERFACE_OSYS WHERE IOS_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = @TYPE_HORLOGE
				DELETE INTERFACE_HORLOGE_THREAD WHERE IHT_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = @TYPE_FICHIER
				DELETE INTERFACE_FICHIER_API WHERE IFA_ID = @v_int_id_phys
			ELSE IF @v_int_type_phys = @TYPE_BDD
			BEGIN
				-- suppression de l'interface complete
				DELETE ECHANGE_LS WHERE ECL_INTERFACE = @v_int_id_phys
				
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE ECHANGE WHERE ECH_INTERFACE = @v_int_id_log
					SET @v_error = @@ERROR
					IF @v_error = 0
						DELETE INTERFACE_BDD_LS WHERE IBL_ID = @v_int_id_phys
				END
			END
			ELSE IF @v_int_type_phys = @TYPE_SOCKET
			BEGIN
				-- suppression des libelles
				DECLARE c_trad CURSOR LOCAL
				FOR SELECT CNX_ID, CNX_TRADUCTION FROM CONNEXION WHERE CNX_INTERFACE = @v_int_id_phys AND CNX_TRADUCTION IS NOT NULL
				FOR UPDATE
				OPEN c_trad
				FETCH NEXT FROM c_trad INTO @v_id, @v_tra_id2
				
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					DELETE CONNEXION WHERE CNX_ID = @v_id
					SET @v_error = @@ERROR
					IF @v_error = 0
						EXEC @v_error = LIB_TRADUCTION @ACTION_DELETE, NULL, NULL, @v_tra_id2 out
					FETCH NEXT FROM c_trad INTO @v_id, @v_tra_id2
				END
				
				CLOSE c_trad
				DEALLOCATE c_trad
				
				IF @v_error = 0
				BEGIN
					-- suppression des connexions
					DELETE CONNEXION WHERE CNX_INTERFACE = @v_int_id_phys;
					SET @v_error = @@ERROR
					IF @v_error = 0
						DELETE INTERFACE_SOCKET_TCPIP WHERE IST_ID = @v_int_id_phys;
				END
			END
			
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE INTERFACE WHERE INT_ID_LOG = @v_int_id_log
				SET @v_error = @@ERROR
			
				IF @v_error = 0
				BEGIN
					DELETE INTERFACE_PHYSIQUE WHERE IPY_ID  = @v_int_id_phys
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC @v_error = CFG_ABONNE @v_action, NULL, @v_int_id_log, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @v_tra_id out, @v_retour out
						
						SET @v_error = @@ERROR
						IF @v_error = 0
							SET @v_retour = 0
					END
				END
			END
		END
		ELSE IF @v_ssaction = @SSACT_UPDATE_PART_ITF
		BEGIN
			IF @v_int_type_phys = @TYPE_BDD
			BEGIN
				-- suppression d'une table en particulier
				DELETE ECHANGE_LS WHERE ECL_ECHANGE = @v_bdd_table_locale
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE ECHANGE WHERE ECH_TABLE = @v_bdd_table_locale
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
			ELSE IF @v_int_type_phys = @TYPE_SOCKET
			BEGIN
				SELECT @v_tra_id2 = CNX_TRADUCTION FROM CONNEXION WHERE CNX_ID = @v_socket_cnx_id
				DELETE CONNEXION WHERE CNX_ID = @v_socket_cnx_id
				
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @ACTION_DELETE, NULL, NULL, @v_tra_id2 out
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
		END
	END

	IF ((@v_error = 0) AND (@v_retour = 0))
		COMMIT TRAN
	ELSE
		ROLLBACK TRAN
	RETURN @v_error

